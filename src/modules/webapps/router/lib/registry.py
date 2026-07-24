#!/usr/bin/env python3

from __future__ import annotations

import argparse
import configparser
import json
import os
import re
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.parse import urlsplit


SCHEMA = 1
DESKTOP_GLOB = "cachycaos-webapp-*.desktop"


def desktop_value(entry: configparser.SectionProxy, key: str) -> str:
    return entry.get(key, "").strip()


def canonical_origin(raw_url: str) -> str:
    parsed = urlsplit(raw_url)
    scheme = parsed.scheme.lower()

    if scheme not in {"http", "https"}:
        raise ValueError("solo se admiten URLs HTTP o HTTPS")
    if not parsed.hostname:
        raise ValueError("la URL no contiene un dominio")
    if parsed.username or parsed.password:
        raise ValueError("la URL no puede contener credenciales")

    host = parsed.hostname.encode("idna").decode("ascii").lower()
    if ":" in host:
        host = f"[{host}]"

    port = parsed.port
    if port and not (
        (scheme == "http" and port == 80)
        or (scheme == "https" and port == 443)
    ):
        return f"{scheme}://{host}:{port}"

    return f"{scheme}://{host}"


def permission_for_origin(origin: str) -> str:
    parsed = urlsplit(origin)
    host = parsed.hostname or ""

    if ":" in host:
        host = f"[{host}]"

    return f"{parsed.scheme}://{host}/*"


def parse_desktop(path: Path) -> dict[str, str] | None:
    parser = configparser.ConfigParser(
        interpolation=None,
        strict=False,
    )
    parser.optionxform = str
    parser.read(path, encoding="utf-8")

    if not parser.has_section("Desktop Entry"):
        return None

    entry = parser["Desktop Entry"]
    if desktop_value(entry, "X-CachycaOS-WebApp").lower() != "true":
        return None
    if desktop_value(entry, "X-CachycaOS-WebApp-Router").lower() == "false":
        return None

    raw_url = desktop_value(entry, "X-CachycaOS-WebApp-URL")
    if not raw_url:
        return None

    origin = canonical_origin(raw_url)
    route_id = path.stem.removeprefix("cachycaos-webapp-")
    name = desktop_value(entry, "Name") or route_id
    window_class = desktop_value(entry, "StartupWMClass")

    if not window_class:
        hostname = urlsplit(origin).hostname or ""
        window_class = f"vivaldi-{hostname}__-Default"

    return {
        "id": route_id,
        "name": name,
        "origin": origin,
        "window_class": window_class,
    }


def discover_routes(applications_dir: Path) -> list[dict[str, str]]:
    by_origin: dict[str, dict[str, str]] = {}

    for path in sorted(applications_dir.glob(DESKTOP_GLOB)):
        try:
            route = parse_desktop(path)
        except (OSError, UnicodeError, ValueError) as error:
            print(f"⚠ {path.name}: {error}", file=os.sys.stderr)
            continue

        if route is not None:
            by_origin.setdefault(route["origin"], route)

    return sorted(by_origin.values(), key=lambda route: route["id"])


def rendered_json(data: object) -> str:
    return json.dumps(
        data,
        ensure_ascii=False,
        indent=2,
        sort_keys=False,
    ) + "\n"


def exact_regex(value: str) -> str:
    return "^" + re.sub(r"([.^$*+?{}\[\]\\|()])", r"\\\1", value) + "$"


def rendered_hyprland_rules(routes: list[dict[str, str]]) -> str:
    lines = [
        "-- N.E.S.T. managed WebApp activation rules",
        "-- Generated from cachycaos-webapp-*.desktop; do not edit manually.",
        "",
    ]

    for route in routes:
        rule_name = f"nest-webapp-{route['id']}-focus"
        class_regex = exact_regex(route["window_class"])
        lines.extend([
            "hl.window_rule({",
            f"    name = {json.dumps(rule_name, ensure_ascii=False)},",
            "    match = {",
            f"        class = {json.dumps(class_regex, ensure_ascii=False)},",
            "    },",
            "    focus_on_activate = true,",
            "})",
            "",
        ])

    lines.append("return true")
    return "\n".join(lines) + "\n"


def write_if_changed(path: Path, content: str) -> bool:
    try:
        if path.read_text(encoding="utf-8") == content:
            return False
    except FileNotFoundError:
        pass

    path.parent.mkdir(parents=True, exist_ok=True)

    with NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as temporary:
        temporary.write(content)
        temporary_path = Path(temporary.name)

    temporary_path.chmod(0o644)
    os.replace(temporary_path, path)
    return True


def build_registry(
    applications_dir: Path,
    manifest_template: Path,
    output_dir: Path,
    hypr_output: Path | None = None,
) -> tuple[bool, list[dict[str, str]]]:
    routes = discover_routes(applications_dir)
    manifest = json.loads(manifest_template.read_text(encoding="utf-8"))
    manifest["host_permissions"] = sorted({
        permission_for_origin(route["origin"])
        for route in routes
    })

    registry = {
        "schema": SCHEMA,
        "routes": routes,
    }

    changed = write_if_changed(
        output_dir / "manifest.json",
        rendered_json(manifest),
    )
    changed = write_if_changed(
        output_dir / "routes.json",
        rendered_json(registry),
    ) or changed
    if hypr_output is not None:
        changed = write_if_changed(
            hypr_output,
            rendered_hyprland_rules(routes),
        ) or changed

    return changed, routes


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Genera el registro del N.E.S.T. WebApp Router.",
    )
    parser.add_argument("--applications", type=Path, required=True)
    parser.add_argument("--manifest-template", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--hypr-output", type=Path)
    args = parser.parse_args()

    changed, routes = build_registry(
        args.applications,
        args.manifest_template,
        args.output,
        args.hypr_output,
    )
    state = "changed" if changed else "unchanged"
    print(f"{state}\t{len(routes)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
