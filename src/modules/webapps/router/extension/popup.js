function addStatusRow(list, label, value) {
  const row = document.createElement("div");
  const term = document.createElement("dt");
  const description = document.createElement("dd");

  term.textContent = label;
  description.textContent = String(value);
  row.append(term, description);
  list.append(row);
}

async function renderStatus() {
  const list = document.querySelector("#status");
  const { lastStatus } = await chrome.storage.local.get("lastStatus");

  list.replaceChildren();

  if (!lastStatus) {
    addStatusRow(list, "Estado", "Sin eventos registrados");
    return;
  }

  addStatusRow(list, "Resultado", lastStatus.outcome);

  if (lastStatus.url) {
    addStatusRow(list, "URL", lastStatus.url);
  }

  if (lastStatus.sourceWindowType) {
    addStatusRow(
      list,
      "Origen",
      `${lastStatus.sourceWindowType} · ${lastStatus.sourceWindowId}`,
    );
  }

  if (lastStatus.targetWindowType) {
    addStatusRow(
      list,
      "Destino",
      `${lastStatus.targetWindowType} · ${lastStatus.targetWindowId}`,
    );
  }

  if (lastStatus.message) {
    addStatusRow(list, "Detalle", lastStatus.message);
  }

  addStatusRow(list, "Momento", lastStatus.at);
}

async function renderWindows() {
  const container = document.querySelector("#windows");
  const windows = await chrome.windows.getAll({ populate: true });

  container.replaceChildren();

  if (windows.length === 0) {
    const empty = document.createElement("p");
    empty.className = "empty";
    empty.textContent = "No se encontraron ventanas.";
    container.append(empty);
    return;
  }

  for (const window of windows.sort((left, right) => left.id - right.id)) {
    const card = document.createElement("article");
    const title = document.createElement("strong");
    const summary = document.createElement("span");
    const urls = document.createElement("span");

    card.className = "window";
    title.textContent = `Ventana ${window.id} · ${window.type}`;
    summary.textContent = `${window.tabs?.length ?? 0} pestaña(s)`;
    urls.textContent = (window.tabs ?? [])
      .map((tab) => tab.url ?? "(URL no disponible)")
      .join(" · ");

    card.append(title, summary, urls);
    container.append(card);
  }
}

async function refresh() {
  await Promise.all([
    renderStatus(),
    renderWindows(),
  ]);
}

document.querySelector("#refresh").addEventListener("click", () => {
  void refresh();
});

void refresh();
