import assert from "node:assert/strict";
import test from "node:test";

import {
  isIndependentAppWindow,
  matchRoute,
  matchingAppTabs,
  selectTarget,
} from "../extension/router-core.mjs";

const incomingUrl = "https://music.youtube.com/library/playlists";

test("reconoce únicamente URLs de YouTube Music", () => {
  assert.equal(matchRoute(incomingUrl)?.id, "youtube-music");
  assert.equal(matchRoute("https://www.youtube.com/watch?v=123"), null);
  assert.equal(matchRoute("not-a-url"), null);
});

test("considera popup y app como ventanas independientes", () => {
  assert.equal(isIndependentAppWindow({ type: "popup" }), true);
  assert.equal(isIndependentAppWindow({ type: "app" }), true);
  assert.equal(isIndependentAppWindow({ type: "normal" }), false);
});

test("no confunde una pestaña normal con la WebApp", () => {
  const windows = [
    {
      id: 10,
      type: "normal",
      tabs: [{ id: 100, url: incomingUrl }],
    },
  ];

  assert.deepEqual(matchingAppTabs(windows, 10, incomingUrl), []);
  assert.equal(selectTarget(windows, 10, incomingUrl), null);
});

test("selecciona una WebApp independiente y excluye el origen", () => {
  const windows = [
    {
      id: 10,
      type: "normal",
      tabs: [{ id: 100, url: incomingUrl }],
    },
    {
      id: 20,
      type: "popup",
      tabs: [{
        id: 200,
        url: "https://music.youtube.com/",
      }],
    },
  ];

  const target = selectTarget(windows, 10, incomingUrl);

  assert.equal(target?.window.id, 20);
  assert.equal(target?.tab.id, 200);
});

test("prefiere la ventana enfocada y después la más reciente", () => {
  const windows = [
    {
      id: 20,
      type: "popup",
      focused: false,
      tabs: [{
        id: 200,
        url: "https://music.youtube.com/",
      }],
    },
    {
      id: 30,
      type: "app",
      focused: true,
      tabs: [{
        id: 300,
        url: "https://music.youtube.com/explore",
      }],
    },
  ];

  assert.equal(selectTarget(windows, 99, incomingUrl)?.window.id, 30);

  windows[1].focused = false;

  assert.equal(selectTarget(windows, 99, incomingUrl)?.window.id, 30);
});
