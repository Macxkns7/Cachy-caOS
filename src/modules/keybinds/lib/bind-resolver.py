#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path


MODULE_DIR = Path.home() / ".local/share/cachycaos/modules/keybinds"
CACHE_DIR = MODULE_DIR / "cache"
DEFAULT_RUNTIME = CACHE_DIR / "runtime.tsv"
DEFAULT_SOURCE = CACHE_DIR / "source.tsv"
DEFAULT_OUTPUT = CACHE_DIR / "enriched.tsv"


@dataclass
class RuntimeBinding:
    identity: str
    combo: str
    fallback_action: str
    runtime_description: str
    dispatcher: str
    runtime_argument: str
    submap: str
    flags: str


@dataclass
class SourceBinding:
    combo: str
    category: str
    description: str
    action_type: str
    argument: str
    source_line: str


@dataclass
class EnrichedBinding:
    identity: str
    combo: str
    category: str
    description: str
    action_type: str
    argument: str
    origin: str
    source_line: str
    dispatcher: str
    runtime_argument: str
    submap: str
    flags: str


KEY_ALIASES = {
    # Volumen
    "SUBIR VOLUMEN": "XF86AUDIORAISEVOLUME",
    "XF86AUDIORAISEVOLUME": "XF86AUDIORAISEVOLUME",
    "BAJAR VOLUMEN": "XF86AUDIOLOWERVOLUME",
    "XF86AUDIOLOWERVOLUME": "XF86AUDIOLOWERVOLUME",
    "SILENCIAR AUDIO": "XF86AUDIOMUTE",
    "XF86AUDIOMUTE": "XF86AUDIOMUTE",
    "SILENCIAR MICRÓFONO": "XF86AUDIOMICMUTE",
    "SILENCIAR MICROFONO": "XF86AUDIOMICMUTE",
    "XF86AUDIOMICMUTE": "XF86AUDIOMICMUTE",

    # Brillo
    "SUBIR BRILLO": "XF86MONBRIGHTNESSUP",
    "XF86MONBRIGHTNESSUP": "XF86MONBRIGHTNESSUP",
    "BAJAR BRILLO": "XF86MONBRIGHTNESSDOWN",
    "XF86MONBRIGHTNESSDOWN": "XF86MONBRIGHTNESSDOWN",

    # Multimedia
    "SIGUIENTE PISTA": "XF86AUDIONEXT",
    "XF86AUDIONEXT": "XF86AUDIONEXT",
    "PISTA ANTERIOR": "XF86AUDIOPREV",
    "XF86AUDIOPREV": "XF86AUDIOPREV",
    "REPRODUCIR": "XF86AUDIOPLAY",
    "XF86AUDIOPLAY": "XF86AUDIOPLAY",
    "PAUSA": "XF86AUDIOPAUSE",
    "XF86AUDIOPAUSE": "XF86AUDIOPAUSE",

    # Ratón
    "RUEDA ABAJO": "MOUSE_DOWN",
    "MOUSE_DOWN": "MOUSE_DOWN",
    "RUEDA ARRIBA": "MOUSE_UP",
    "MOUSE_UP": "MOUSE_UP",
    "CLIC IZQUIERDO": "MOUSE:272",
    "MOUSE:272": "MOUSE:272",
    "CLIC DERECHO": "MOUSE:273",
    "MOUSE:273": "MOUSE:273",
    "CLIC CENTRAL": "MOUSE:274",
    "MOUSE:274": "MOUSE:274",
}


def normalize_spaces(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def canonical_key(value: str) -> str:
    normalized = normalize_spaces(value).upper()
    return KEY_ALIASES.get(normalized, normalized)


def canonical_combo(combo: str) -> str:
    parts = [
        normalize_spaces(part).upper()
        for part in combo.split("+")
        if normalize_spaces(part)
    ]

    modifiers: list[str] = []
    key_parts: list[str] = []

    modifier_order = ["SUPER", "CTRL", "ALT", "SHIFT"]

    for part in parts:
        aliases = {
            "CONTROL": "CTRL",
            "MOD4": "SUPER",
            "WIN": "SUPER",
        }

        part = aliases.get(part, part)

        if part in modifier_order:
            modifiers.append(part)
        else:
            key_parts.append(part)

    ordered_modifiers = [
        modifier
        for modifier in modifier_order
        if modifier in modifiers
    ]

    key = canonical_key(" + ".join(key_parts))

    if ordered_modifiers and key:
        return " + ".join([*ordered_modifiers, key])

    if ordered_modifiers:
        return " + ".join(ordered_modifiers)

    return key


def category_for(binding: SourceBinding) -> str:
    combo = canonical_combo(binding.combo)
    action = binding.action_type
    description = binding.description.lower()

    if action == "exec":
        if any(
            word in description
            for word in (
                "terminal",
                "archivos",
                "lanzador",
            )
        ):
            return "Aplicaciones"

        if "salida" in description:
            return "Sistema"

        if any(
            token in combo
            for token in (
                "XF86AUDIO",
                "XF86MONBRIGHTNESS",
            )
        ):
            return "Multimedia"

    if action.startswith("workspace"):
        return "Workspaces"

    if action == "window.move" and "workspace" in description:
        return "Workspaces"

    if action.startswith("window.") or action in {"focus", "layout"}:
        return "Ventanas"

    return binding.category or "General"


def read_tsv(path: Path) -> list[list[str]]:
    with path.open(
        "r",
        encoding="utf-8",
        newline="",
    ) as handle:
        return list(csv.reader(handle, delimiter="\t"))


def load_runtime(path: Path) -> list[RuntimeBinding]:
    rows = read_tsv(path)
    bindings: list[RuntimeBinding] = []

    for number, row in enumerate(rows, start=1):
        if len(row) != 8:
            raise ValueError(
                f"{path}:{number}: se esperaban 8 columnas, "
                f"pero llegaron {len(row)}."
            )

        bindings.append(RuntimeBinding(*row))

    return bindings


def load_source(path: Path) -> list[SourceBinding]:
    rows = read_tsv(path)
    bindings: list[SourceBinding] = []

    for number, row in enumerate(rows, start=1):
        if len(row) != 6:
            raise ValueError(
                f"{path}:{number}: se esperaban 6 columnas, "
                f"pero llegaron {len(row)}."
            )

        bindings.append(SourceBinding(*row))

    return bindings


def resolve(
    runtime_bindings: list[RuntimeBinding],
    source_bindings: list[SourceBinding],
) -> tuple[list[EnrichedBinding], list[RuntimeBinding], list[SourceBinding]]:
    source_index: dict[str, list[SourceBinding]] = {}

    for binding in source_bindings:
        key = canonical_combo(binding.combo)
        source_index.setdefault(key, []).append(binding)

    enriched: list[EnrichedBinding] = []
    unmatched_runtime: list[RuntimeBinding] = []
    used_source_ids: set[int] = set()

    for runtime in runtime_bindings:
        key = canonical_combo(runtime.combo)
        candidates = source_index.get(key, [])

        source = next(
            (
                candidate
                for candidate in candidates
                if id(candidate) not in used_source_ids
            ),
            None,
        )

        if source is None:
            unmatched_runtime.append(runtime)

            enriched.append(
                EnrichedBinding(
                    identity=runtime.identity,
                    combo=runtime.combo,
                    category="Sin clasificar",
                    description=runtime.fallback_action,
                    action_type=runtime.dispatcher or "desconocido",
                    argument=runtime.runtime_argument,
                    origin="runtime",
                    source_line="",
                    dispatcher=runtime.dispatcher,
                    runtime_argument=runtime.runtime_argument,
                    submap=runtime.submap,
                    flags=runtime.flags,
                )
            )

            continue

        used_source_ids.add(id(source))

        enriched.append(
            EnrichedBinding(
                identity=runtime.identity,
                combo=runtime.combo,
                category=category_for(source),
                description=(
                    runtime.runtime_description
                    or source.description
                    or runtime.fallback_action
                ),
                action_type=source.action_type,
                argument=source.argument,
                origin="hyprland.lua",
                source_line=source.source_line,
                dispatcher=runtime.dispatcher,
                runtime_argument=runtime.runtime_argument,
                submap=runtime.submap,
                flags=runtime.flags,
            )
        )

    unmatched_source = [
        binding
        for binding in source_bindings
        if id(binding) not in used_source_ids
    ]

    return enriched, unmatched_runtime, unmatched_source


def write_output(
    bindings: list[EnrichedBinding],
    path: Path,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open(
        "w",
        encoding="utf-8",
        newline="",
    ) as handle:
        writer = csv.writer(
            handle,
            delimiter="\t",
            lineterminator="\n",
        )

        for binding in bindings:
            writer.writerow(
                [
                    binding.identity,
                    binding.combo,
                    binding.category,
                    binding.description,
                    binding.action_type,
                    binding.argument,
                    binding.origin,
                    binding.source_line,
                    binding.dispatcher,
                    binding.runtime_argument,
                    binding.submap,
                    binding.flags,
                ]
            )


def print_report(
    enriched: list[EnrichedBinding],
    unmatched_runtime: list[RuntimeBinding],
    unmatched_source: list[SourceBinding],
) -> None:
    matched = len(enriched) - len(unmatched_runtime)

    print("Cachy-caOS Bind Resolver")
    print()
    print(f"Runtime:             {len(enriched)}")
    print(f"Emparejados:         {matched}")
    print(f"Runtime sin fuente:  {len(unmatched_runtime)}")
    print(f"Fuente sin runtime:  {len(unmatched_source)}")
    print()

    if unmatched_runtime:
        print("Atajos activos sin coincidencia de fuente:")

        for binding in unmatched_runtime:
            print(f"  - {binding.combo}")

        print()

    if unmatched_source:
        print("Atajos de fuente no encontrados en runtime:")

        for binding in unmatched_source:
            print(f"  - {binding.combo}")

        print()


def print_bindings(bindings: list[EnrichedBinding]) -> None:
    for binding in bindings:
        print(
            f"{binding.combo:<34} | "
            f"{binding.category:<13} | "
            f"{binding.description}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Cruza los atajos activos de Hyprland con "
            "su configuración Lua."
        )
    )

    parser.add_argument(
        "--runtime",
        type=Path,
        default=DEFAULT_RUNTIME,
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
    )
    parser.add_argument(
        "--print",
        action="store_true",
        dest="print_output",
    )

    args = parser.parse_args()

    for path in (args.runtime, args.source):
        if not path.is_file():
            print(
                f"Error: no existe {path}",
                file=sys.stderr,
            )
            return 1

    try:
        runtime_bindings = load_runtime(args.runtime)
        source_bindings = load_source(args.source)

        enriched, unmatched_runtime, unmatched_source = resolve(
            runtime_bindings,
            source_bindings,
        )
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    write_output(enriched, args.output)

    print_report(
        enriched,
        unmatched_runtime,
        unmatched_source,
    )

    if args.print_output:
        print_bindings(enriched)

    return 0 if not unmatched_runtime and not unmatched_source else 2


if __name__ == "__main__":
    raise SystemExit(main())
