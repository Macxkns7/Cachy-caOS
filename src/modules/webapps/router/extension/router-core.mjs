export const APP_WINDOW_TYPES = Object.freeze(["app", "popup"]);

export function matchRoute(routes, rawUrl) {
  let parsed;

  try {
    parsed = new URL(rawUrl);
  } catch {
    return null;
  }

  return (routes ?? []).find(
    (route) => parsed.origin === route?.origin,
  ) ?? null;
}

export function isIndependentAppWindow(window) {
  return APP_WINDOW_TYPES.includes(window?.type);
}

export function matchingAppTabs(
  routes,
  windows,
  sourceWindowId,
  rawUrl,
) {
  const route = matchRoute(routes, rawUrl);

  if (!route) {
    return [];
  }

  const matches = [];

  for (const window of windows ?? []) {
    if (
      window?.id === sourceWindowId ||
      !isIndependentAppWindow(window)
    ) {
      continue;
    }

    for (const tab of window.tabs ?? []) {
      if (matchRoute(routes, tab?.url)?.id !== route.id) {
        continue;
      }

      matches.push({
        route,
        tab,
        window,
      });
    }
  }

  return matches;
}

export function selectTarget(routes, windows, sourceWindowId, rawUrl) {
  const matches = matchingAppTabs(
    routes,
    windows,
    sourceWindowId,
    rawUrl,
  );

  if (matches.length === 0) {
    return null;
  }

  return matches.sort((left, right) => {
    if (left.window.focused !== right.window.focused) {
      return left.window.focused ? -1 : 1;
    }

    return (right.window.id ?? -1) - (left.window.id ?? -1);
  })[0];
}
