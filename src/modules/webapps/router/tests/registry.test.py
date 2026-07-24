#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest


ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "lib" / "registry.py"
SPEC = importlib.util.spec_from_file_location("nest_registry", REGISTRY_PATH)
assert SPEC is not None and SPEC.loader is not None
registry = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(registry)


def write_desktop(
    directory: Path,
    slug: str,
    name: str,
    url: str,
    *,
    managed: bool = True,
    router_enabled: bool | None = None,
    window_class: str | None = None,
) -> None:
    lines = [
        "[Desktop Entry]",
        "Type=Application",
        f"Name={name}",
        f"X-CachycaOS-WebApp={'true' if managed else 'false'}",
        f"X-CachycaOS-WebApp-URL={url}",
    ]

    if window_class is not None:
        lines.append(f"StartupWMClass={window_class}")

    if router_enabled is not None:
        lines.append(
            "X-CachycaOS-WebApp-Router="
            + ("true" if router_enabled else "false"),
        )

    (directory / f"cachycaos-webapp-{slug}.desktop").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


class RegistryTests(unittest.TestCase):
    def test_discovers_managed_routes_and_honours_opt_out(self) -> None:
        with TemporaryDirectory() as temporary:
            applications = Path(temporary)
            write_desktop(
                applications,
                "chatgpt",
                "ChatGPT",
                "https://chatgpt.com/c/example",
            )
            write_desktop(
                applications,
                "music",
                "YouTube Music",
                "https://music.youtube.com/library",
            )
            write_desktop(
                applications,
                "disabled",
                "Deshabilitada",
                "https://disabled.example",
                router_enabled=False,
            )
            write_desktop(
                applications,
                "external",
                "Externa",
                "https://external.example",
                managed=False,
            )

            routes = registry.discover_routes(applications)

            self.assertEqual(
                [route["id"] for route in routes],
                ["chatgpt", "music"],
            )
            self.assertEqual(routes[0]["origin"], "https://chatgpt.com")
            self.assertEqual(
                routes[1]["origin"],
                "https://music.youtube.com",
            )

    def test_deduplicates_routes_by_origin(self) -> None:
        with TemporaryDirectory() as temporary:
            applications = Path(temporary)
            write_desktop(
                applications,
                "first",
                "Primera",
                "https://example.com/one",
            )
            write_desktop(
                applications,
                "second",
                "Segunda",
                "https://example.com/two",
            )

            routes = registry.discover_routes(applications)

            self.assertEqual(len(routes), 1)
            self.assertEqual(routes[0]["id"], "first")

    def test_normalizes_default_ports_and_rejects_credentials(self) -> None:
        self.assertEqual(
            registry.canonical_origin("HTTPS://Example.COM:443/path"),
            "https://example.com",
        )
        self.assertEqual(
            registry.canonical_origin("http://example.com:8080/path"),
            "http://example.com:8080",
        )

        with self.assertRaises(ValueError):
            registry.canonical_origin(
                "https://manuel:secret@example.com/path",
            )

    def test_builds_minimal_permissions_atomically(self) -> None:
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            applications = root / "applications"
            output = root / "output"
            hypr_output = root / "hypr" / "cachycaos" / "webapps.lua"
            applications.mkdir()
            output.mkdir()

            write_desktop(
                applications,
                "chatgpt",
                "ChatGPT",
                "https://chatgpt.com",
                window_class="vivaldi-chatgpt.com__-Default",
            )
            write_desktop(
                applications,
                "music",
                "YouTube Music",
                "https://music.youtube.com",
            )

            changed, routes = registry.build_registry(
                applications,
                ROOT / "extension" / "manifest.json",
                output,
                hypr_output,
            )
            unchanged, _ = registry.build_registry(
                applications,
                ROOT / "extension" / "manifest.json",
                output,
                hypr_output,
            )

            manifest = json.loads(
                (output / "manifest.json").read_text(encoding="utf-8"),
            )
            generated = json.loads(
                (output / "routes.json").read_text(encoding="utf-8"),
            )

            self.assertTrue(changed)
            self.assertFalse(unchanged)
            self.assertEqual(len(routes), 2)
            self.assertEqual(
                manifest["host_permissions"],
                [
                    "https://chatgpt.com/*",
                    "https://music.youtube.com/*",
                ],
            )
            self.assertEqual(generated["schema"], 1)
            self.assertEqual(len(generated["routes"]), 2)
            hyprland_rules = hypr_output.read_text(encoding="utf-8")
            self.assertIn(
                'name = "nest-webapp-chatgpt-focus"',
                hyprland_rules,
            )
            self.assertIn(
                'class = "^vivaldi-chatgpt\\\\.com__-Default$"',
                hyprland_rules,
            )
            self.assertEqual(
                hyprland_rules.count("focus_on_activate = true"),
                2,
            )


if __name__ == "__main__":
    unittest.main()
