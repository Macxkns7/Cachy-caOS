#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


DEFAULT_CONFIG = Path.home() / ".config/hypr/hyprland.lua"


@dataclass
class Binding:
    combo: str
    category: str
    description: str
    action_type: str
    argument: str
    event: str
    source_path: str
    source_line: int


def normalize_combo(combo: str) -> str:
    parts = [part.strip() for part in combo.split("+")]
    normalized: list[str] = []

    for part in parts:
        upper = part.upper()

        aliases = {
            "CONTROL": "CTRL",
            "WIN": "SUPER",
            "MOD4": "SUPER",
        }

        normalized.append(aliases.get(upper, upper))

    return " + ".join(normalized)


def category_from_comment(comment: str) -> str | None:
    text = comment.strip().lower()

    rules = [
        ("multimedia", "Multimedia"),
        ("volume", "Multimedia"),
        ("brightness", "Multimedia"),
        ("workspace", "Workspaces"),
        ("focus", "Ventanas"),
        ("move/resize", "Ventanas"),
        ("move active window", "Workspaces"),
        ("special workspace", "Workspaces"),
        ("example binds", "Aplicaciones"),
        ("keybindings", "General"),
    ]

    for needle, category in rules:
        if needle in text:
            return category

    return None


def clean_lua_string(value: str) -> str:
    value = value.strip()

    if (
        len(value) >= 2
        and value[0] in {'"', "'"}
        and value[-1] == value[0]
    ):
        return value[1:-1]

    return value


def resolve_key_expression(
    expression: str,
    variables: dict[str, str],
    loop_values: dict[str, int] | None = None,
) -> str:
    loop_values = loop_values or {}
    pieces = [piece.strip() for piece in expression.split("..")]
    result: list[str] = []

    for piece in pieces:
        if not piece:
            continue

        if piece in variables:
            result.append(variables[piece])
        elif piece in loop_values:
            result.append(str(loop_values[piece]))
        elif re.fullmatch(r"\d+", piece):
            result.append(piece)
        else:
            result.append(clean_lua_string(piece))

    return normalize_combo("".join(result))


def resolve_exec_argument(
    argument: str,
    variables: dict[str, str],
) -> str:
    value = argument.strip()

    if value in variables:
        return variables[value]

    return clean_lua_string(value)


def describe_exec(command: str) -> tuple[str, str]:
    rules = [
        (r"^kitty$", "Abrir terminal Kitty"),
        (r"^dolphin$", "Abrir gestor de archivos Dolphin"),
        (r"^hyprlauncher$", "Abrir lanzador de aplicaciones"),
        (r"^wpctl set-volume .*5%\+$", "Subir volumen"),
        (r"^wpctl set-volume .*5%-$", "Bajar volumen"),
        (r"^wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle$", "Silenciar o restaurar audio"),
        (r"^wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle$", "Silenciar o restaurar micrófono"),
        (r"^brightnessctl .*5%\+$", "Subir brillo"),
        (r"^brightnessctl .*5%-$", "Bajar brillo"),
        (r"^playerctl next$", "Siguiente pista"),
        (r"^playerctl previous$", "Pista anterior"),
        (r"^playerctl play-pause$", "Reproducir o pausar"),
        (r"hyprshutdown", "Abrir opciones de salida"),
    ]

    for pattern, description in rules:
        if re.search(pattern, command):
            return description, command

    return f"Ejecutar: {command}", command


def describe_dispatcher(
    dispatcher: str,
    variables: dict[str, str],
) -> tuple[str, str, str]:
    dispatcher = dispatcher.strip()

    exec_match = re.fullmatch(
        r"hl\.dsp\.exec_cmd\((.*)\)",
        dispatcher,
        flags=re.S,
    )

    if exec_match:
        command = resolve_exec_argument(exec_match.group(1), variables)
        description, argument = describe_exec(command)
        return description, "exec", argument

    known_rules = [
        (
            r"hl\.dsp\.window\.close\(\)",
            "Cerrar ventana activa",
            "window.close",
            "",
        ),
        (
            r'hl\.dsp\.window\.float\(\{\s*action\s*=\s*"toggle"\s*\}\)',
            "Alternar ventana flotante",
            "window.float",
            "toggle",
        ),
        (
            r"hl\.dsp\.window\.pseudo\(\)",
            "Alternar pseudotiling",
            "window.pseudo",
            "",
        ),
        (
            r'hl\.dsp\.layout\("togglesplit"\)',
            "Cambiar orientación de la división",
            "layout",
            "togglesplit",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*direction\s*=\s*"left"\s*\}\)',
            "Mover foco a la izquierda",
            "focus",
            "left",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*direction\s*=\s*"right"\s*\}\)',
            "Mover foco a la derecha",
            "focus",
            "right",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*direction\s*=\s*"up"\s*\}\)',
            "Mover foco hacia arriba",
            "focus",
            "up",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*direction\s*=\s*"down"\s*\}\)',
            "Mover foco hacia abajo",
            "focus",
            "down",
        ),
        (
            r'hl\.dsp\.workspace\.toggle_special\("magic"\)',
            "Mostrar u ocultar workspace especial",
            "workspace.special",
            "magic",
        ),
        (
            r'hl\.dsp\.window\.move\(\{\s*workspace\s*=\s*"special:magic"\s*\}\)',
            "Mover ventana al workspace especial",
            "window.move",
            "special:magic",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*workspace\s*=\s*"e\+1"\s*\}\)',
            "Ir al workspace siguiente",
            "workspace.focus",
            "e+1",
        ),
        (
            r'hl\.dsp\.focus\(\{\s*workspace\s*=\s*"e-1"\s*\}\)',
            "Ir al workspace anterior",
            "workspace.focus",
            "e-1",
        ),
        (
            r"hl\.dsp\.window\.drag\(\)",
            "Arrastrar ventana",
            "window.drag",
            "",
        ),
        (
            r"hl\.dsp\.window\.resize\(\)",
            "Redimensionar ventana",
            "window.resize",
            "",
        ),
    ]

    for pattern, description, action_type, argument in known_rules:
        if re.fullmatch(pattern, dispatcher):
            return description, action_type, argument

    return "Acción Lua no reconocida", "lua", dispatcher


def extract_call_arguments(call_text: str) -> tuple[str, str, str]:
    depth = 0
    quote: str | None = None
    escape = False
    parts: list[str] = []
    current: list[str] = []

    for char in call_text:
        if quote:
            current.append(char)

            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == quote:
                quote = None

            continue

        if char in {'"', "'"}:
            quote = char
            current.append(char)
        elif char in "({[":
            depth += 1
            current.append(char)
        elif char in ")}]":
            depth -= 1
            current.append(char)
        elif char == "," and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(char)

    if current:
        parts.append("".join(current).strip())

    while len(parts) < 3:
        parts.append("")

    return parts[0], parts[1], parts[2]


def event_from_options(options: str) -> str:
    rules = (
        (r"\blong_press\s*=\s*true\b", "long_press"),
        (r"\brelease\s*=\s*true\b", "release"),
        (r"\brepeating\s*=\s*true\b", "repeat"),
    )

    for pattern, event in rules:
        if re.search(pattern, options):
            return event

    return "press"


def collect_bind_calls(lines: list[str]) -> list[tuple[int, str]]:
    calls: list[tuple[int, str]] = []
    index = 0

    while index < len(lines):
        line = lines[index]

        if "hl.bind(" not in line:
            index += 1
            continue

        start_line = index + 1
        fragment = line[line.index("hl.bind(") + len("hl.bind("):]
        depth = 1
        quote: str | None = None
        escape = False
        buffer: list[str] = []

        while True:
            for char in fragment:
                if quote:
                    buffer.append(char)

                    if escape:
                        escape = False
                    elif char == "\\":
                        escape = True
                    elif char == quote:
                        quote = None

                    continue

                if char in {'"', "'"}:
                    quote = char
                    buffer.append(char)
                elif char == "(":
                    depth += 1
                    buffer.append(char)
                elif char == ")":
                    depth -= 1

                    if depth == 0:
                        calls.append((start_line, "".join(buffer)))
                        break

                    buffer.append(char)
                else:
                    buffer.append(char)

            if depth == 0:
                break

            index += 1

            if index >= len(lines):
                break

            fragment = "\n" + lines[index]

        index += 1

    return calls


def required_files(path: Path) -> list[Path]:
    text = path.read_text(encoding="utf-8")
    results: list[Path] = []

    for module in re.findall(
        r'require\s*\(\s*["\']([^"\']+)["\']\s*\)',
        text,
    ):
        candidate = path.parent / Path(
            module.replace(".", "/") + ".lua"
        )

        if candidate.is_file():
            results.append(candidate)

    return results


def scan_single_config(path: Path) -> list[Binding]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    variables: dict[str, str] = {}
    bindings: list[Binding] = []
    category_by_line: dict[int, str] = {}

    current_category = "General"

    for number, line in enumerate(lines, start=1):
        stripped = line.strip()

        if stripped.startswith("--"):
            detected = category_from_comment(stripped[2:])

            if detected:
                current_category = detected

        category_by_line[number] = current_category

        variable_match = re.match(
            r'local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(["\'])(.*?)\2',
            stripped,
        )

        if variable_match:
            variables[variable_match.group(1)] = variable_match.group(3)

    calls = collect_bind_calls(lines)

    for line_number, call in calls:
        key_expr, dispatcher_expr, options = extract_call_arguments(call)
        category = category_by_line.get(line_number, "General")
        event = event_from_options(options)

        if " .. key" in key_expr and "workspace = i" in dispatcher_expr:
            for i in range(1, 11):
                key = i % 10
                combo = resolve_key_expression(
                    key_expr,
                    variables,
                    {"i": i, "key": key},
                )

                if "hl.dsp.window.move" in dispatcher_expr:
                    description = f"Mover ventana al workspace {i}"
                    action_type = "window.move"
                else:
                    description = f"Ir al workspace {i}"
                    action_type = "workspace.focus"

                bindings.append(
                    Binding(
                        combo=combo,
                        category="Workspaces",
                        description=description,
                        action_type=action_type,
                        argument=str(i),
                        event=event,
                        source_path=str(path.resolve()),
                        source_line=line_number,
                    )
                )

            continue

        combo = resolve_key_expression(key_expr, variables)
        description, action_type, argument = describe_dispatcher(
            dispatcher_expr,
            variables,
        )

        bindings.append(
            Binding(
                combo=combo,
                category=category,
                description=description,
                action_type=action_type,
                argument=argument,
                event=event,
                source_path=str(path.resolve()),
                source_line=line_number,
            )
        )

    return bindings


def scan_config(path: Path) -> list[Binding]:
    bindings: list[Binding] = []
    visited: set[Path] = set()

    def visit(current: Path) -> None:
        resolved = current.resolve()

        if resolved in visited:
            return

        visited.add(resolved)
        bindings.extend(scan_single_config(current))

        for required in required_files(current):
            visit(required)

    visit(path)
    return bindings


def write_tsv(bindings: list[Binding], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)

    with output.open("w", encoding="utf-8") as handle:
        for binding in bindings:
            fields = [
                binding.combo,
                binding.category,
                binding.description,
                binding.action_type,
                binding.argument,
                binding.event,
                binding.source_path,
                str(binding.source_line),
            ]

            handle.write("\t".join(fields) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Escanea atajos definidos en Hyprland Lua."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
    )
    parser.add_argument(
        "--output",
        type=Path,
    )
    parser.add_argument(
        "--print",
        action="store_true",
        dest="print_output",
    )

    args = parser.parse_args()

    if not args.config.is_file():
        print(
            f"Error: no existe la configuración {args.config}",
            file=sys.stderr,
        )
        return 1

    bindings = scan_config(args.config)

    if args.output:
        write_tsv(bindings, args.output)

    if args.print_output or not args.output:
        for binding in bindings:
            print(
                f"{binding.combo:<38} | "
                f"{binding.category:<12} | "
                f"{binding.description}"
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
