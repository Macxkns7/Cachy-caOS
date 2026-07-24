import {
  matchRoute,
  selectTarget,
} from "./router-core.mjs";

const ROUTE_DELAY_MS = 180;
const MAX_INCOMING_TAB_AGE_MS = 5000;
const pendingTabs = new Set();
const createdAtByTab = new Map();
let registryPromise;

function isoNow() {
  return new Date().toISOString();
}

async function saveStatus(status) {
  await chrome.storage.local.set({
    lastStatus: {
      at: isoNow(),
      ...status,
    },
  });
}

async function loadRegistry() {
  if (!registryPromise) {
    registryPromise = fetch(chrome.runtime.getURL("routes.json"), {
      cache: "no-store",
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`No se pudo leer routes.json: ${response.status}`);
        }

        return response.json();
      })
      .then((registry) => {
        if (registry?.schema !== 1 || !Array.isArray(registry.routes)) {
          throw new Error("El registro de WebApps no es válido.");
        }

        return registry;
      });
  }

  return registryPromise;
}

async function routeIncomingTab(tabId, rawUrl) {
  let route;

  try {
    const registry = await loadRegistry();
    route = matchRoute(registry.routes, rawUrl);
    const createdAt = createdAtByTab.get(tabId);

    if (
      !route ||
      !createdAt ||
      Date.now() - createdAt > MAX_INCOMING_TAB_AGE_MS ||
      pendingTabs.has(tabId)
    ) {
      return;
    }

    pendingTabs.add(tabId);

    await new Promise((resolve) => setTimeout(resolve, ROUTE_DELAY_MS));

    const sourceTab = await chrome.tabs.get(tabId);
    const sourceWindow = await chrome.windows.get(sourceTab.windowId);

    if (sourceWindow.type !== "normal") {
      await saveStatus({
        outcome: "ignored-source-window",
        route: route.id,
        sourceWindowId: sourceWindow.id,
        sourceWindowType: sourceWindow.type,
        url: rawUrl,
      });
      return;
    }

    const windows = await chrome.windows.getAll({ populate: true });
    const target = selectTarget(
      registry.routes,
      windows,
      sourceWindow.id,
      rawUrl,
    );

    if (!target) {
      await saveStatus({
        outcome: "no-independent-webapp-window",
        route: route.id,
        sourceWindowId: sourceWindow.id,
        sourceWindowType: sourceWindow.type,
        url: rawUrl,
      });
      return;
    }

    await chrome.tabs.update(target.tab.id, {
      active: true,
      url: rawUrl,
    });
    await chrome.windows.update(target.window.id, { focused: true });

    // La pestaña intermediaria solo se cierra después de navegar y enfocar
    // correctamente la WebApp. Ante cualquier error permanece intacta.
    await chrome.tabs.remove(sourceTab.id);

    await saveStatus({
      outcome: "routed",
      route: route.id,
      sourceWindowId: sourceWindow.id,
      sourceWindowType: sourceWindow.type,
      targetTabId: target.tab.id,
      targetWindowId: target.window.id,
      targetWindowType: target.window.type,
      url: rawUrl,
    });
  } catch (error) {
    await saveStatus({
      outcome: "error",
      route: route?.id,
      message: error instanceof Error ? error.message : String(error),
      url: rawUrl,
    });
  } finally {
    pendingTabs.delete(tabId);
  }
}

chrome.tabs.onCreated.addListener((tab) => {
  const createdAt = Date.now();

  createdAtByTab.set(tab.id, createdAt);

  setTimeout(() => {
    if (createdAtByTab.get(tab.id) === createdAt) {
      createdAtByTab.delete(tab.id);
    }
  }, MAX_INCOMING_TAB_AGE_MS + 1000);

  const initialUrl = tab.pendingUrl ?? tab.url;

  if (initialUrl) {
    void routeIncomingTab(tab.id, initialUrl);
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (!changeInfo.url) {
    return;
  }

  void routeIncomingTab(tabId, changeInfo.url);
});

chrome.tabs.onRemoved.addListener((tabId) => {
  createdAtByTab.delete(tabId);
  pendingTabs.delete(tabId);
});

chrome.runtime.onInstalled.addListener(() => {
  void loadRegistry()
    .then((registry) => saveStatus({
      outcome: "ready",
      message: `${registry.routes.length} WebApp(s) registrada(s).`,
    }))
    .catch((error) => saveStatus({
      outcome: "error",
      message: error instanceof Error ? error.message : String(error),
    }));
});
