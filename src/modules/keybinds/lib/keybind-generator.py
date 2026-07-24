#!/usr/bin/env python3

from __future__ import annotations

import argparse
import difflib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


MODULE_DIR = Path.home() / ".local/share/cachycaos/modules/keybinds"
DEFAULT_DATA = MODULE_DIR / "data/binds.toml"
DEFAULT_BUILD = MODULE_DIR / "build/keybinds.lua"
DEFAULT_TARGET = Path.home() / ".config/hypr/cachycaos/keybinds.lua"
DEFAULT_BACKUPS = MODULE_DIR / "backups"
HELPERS_DIR = MODULE_DIR / "helpers"
LUA_MODULE = "cachycaos.keybinds"

VALID_MODIFIERS = {"SUPER", "CTRL", "ALT", "SHIFT"}

ACTION_MAP = {
    "window.close": "hl.dsp.window.close()",
    "window.float.toggle": (
        'hl.dsp.window.float({ action = "toggle" })'
    ),
    "window.pseudo": "hl.dsp.window.pseudo()",
    "window.fullscreen": (
        'hl.dsp.window.fullscreen({ action = "toggle" })'
    ),
    "window.drag": "hl.dsp.window.drag()",
    "window.resize": "hl.dsp.window.resize()",
}

ARGUMENT_ACTIONS = {
    "helper",
    "layout",
    "focus",
    "workspace.focus",
    "workspace.special",
    "window.move",
}


@dataclass(frozen=True)
class Bind:
    identifier: str
    enabled: bool
    modifiers: tuple[str, ...]
    key: str
    category: str
    description: str
    action: str
    argument: str | None = None
    event: str = "press"
    locked: bool = False
    mouse: bool = False

    @property
    def combo(self) -> str:
        return " + ".join((*self.modifiers, self.key))


def fail(message: str) -> None:
    raise ValueError(message)


def require_string(
    record: dict[str, Any],
    field: str,
    bind_number: int,
) -> str:
    value = record.get(field)

    if not isinstance(value, str) or not value.strip():
        fail(
            f"bind #{bind_number}: '{field}' debe ser "
            "un texto no vacío."
        )

    return value.strip()


def parse_bind(
    record: dict[str, Any],
    bind_number: int,
) -> Bind:
    identifier = require_string(record, "id", bind_number)
    key = require_string(record, "key", bind_number)
    category = require_string(record, "category", bind_number)
    description = require_string(
        record,
        "description",
        bind_number,
    )
    action = require_string(record, "action", bind_number)

    enabled = record.get("enabled", True)

    if not isinstance(enabled, bool):
        fail(
            f"bind #{bind_number}: 'enabled' debe ser true o false."
        )

    event = record.get("event", "press")

    if event not in {"press", "release", "repeat", "long_press"}:
        fail(
            f"bind #{bind_number}: 'event' debe ser "
            "press, release, repeat o long_press."
        )

    locked = record.get("locked", False)
    mouse = record.get("mouse", False)

    if not isinstance(locked, bool) or not isinstance(mouse, bool):
        fail(
            f"bind #{bind_number}: 'locked' y 'mouse' "
            "deben ser true o false."
        )

    modifiers_raw = record.get("modifiers", [])

    if not isinstance(modifiers_raw, list):
        fail(
            f"bind #{bind_number}: 'modifiers' debe ser una lista."
        )

    modifiers: list[str] = []

    for modifier in modifiers_raw:
        if not isinstance(modifier, str):
            fail(
                f"bind #{bind_number}: modificador no válido."
            )

        normalized = modifier.strip().upper()

        if normalized not in VALID_MODIFIERS:
            fail(
                f"bind #{bind_number}: modificador desconocido "
                f"'{modifier}'."
            )

        if normalized not in modifiers:
            modifiers.append(normalized)

    if not re.fullmatch(r"[A-Za-z0-9:_-]+", key):
        fail(
            f"bind #{bind_number}: tecla no válida '{key}'."
        )

    if (
        action != "exec"
        and action not in ACTION_MAP
        and action not in ARGUMENT_ACTIONS
    ):
        fail(
            f"bind #{bind_number}: acción desconocida '{action}'."
        )

    argument = record.get("argument")

    if action == "exec" or action in ARGUMENT_ACTIONS:
        if not isinstance(argument, str) or not argument.strip():
            fail(
                f"bind #{bind_number}: la acción '{action}' "
                "requiere 'argument'."
            )

        argument = argument.strip()

        if action == "helper" and not re.fullmatch(
            r"[A-Za-z0-9._-]+",
            argument,
        ):
            fail(
                f"bind #{bind_number}: helper no válido "
                f"'{argument}'."
            )
    elif argument is not None:
        fail(
            f"bind #{bind_number}: '{action}' no acepta argument."
        )

    return Bind(
        identifier=identifier,
        enabled=enabled,
        modifiers=tuple(modifiers),
        key=key,
        category=category,
        description=description,
        action=action,
        argument=argument,
        event=event,
        locked=locked,
        mouse=mouse,
    )


def load_binds(path: Path) -> list[Bind]:
    with path.open("rb") as handle:
        document = tomllib.load(handle)

    if document.get("version") != 1:
        fail("El archivo TOML debe declarar version = 1.")

    records = document.get("bind", [])

    if not isinstance(records, list):
        fail("'bind' debe ser una lista de tablas TOML.")

    binds = [
        parse_bind(record, number)
        for number, record in enumerate(records, start=1)
    ]

    identifiers: set[str] = set()
    combinations: set[str] = set()

    for bind in binds:
        if bind.identifier in identifiers:
            fail(f"ID duplicado: {bind.identifier}")

        identifiers.add(bind.identifier)

        if not bind.enabled:
            continue

        combo = f"{bind.event}:{bind.combo.upper()}"

        if combo in combinations:
            fail(f"Combinación duplicada: {bind.combo}")

        combinations.add(combo)

    return binds


def lua_quote(value: str) -> str:
    escaped = (
        value
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )

    return f'"{escaped}"'


def render_dispatcher(bind: Bind) -> str:
    if bind.action == "exec":
        assert bind.argument is not None
        return f"hl.dsp.exec_cmd({lua_quote(bind.argument)})"

    if bind.action == "helper":
        assert bind.argument is not None
        helper = HELPERS_DIR / bind.argument
        return f"hl.dsp.exec_cmd({lua_quote(str(helper))})"

    if bind.action in ACTION_MAP:
        return ACTION_MAP[bind.action]

    assert bind.argument is not None
    argument = lua_quote(bind.argument)

    if bind.action == "layout":
        return f"hl.dsp.layout({argument})"
    if bind.action == "focus":
        return f"hl.dsp.focus({{ direction = {argument} }})"
    if bind.action == "workspace.focus":
        return f"hl.dsp.focus({{ workspace = {argument} }})"
    if bind.action == "workspace.special":
        return f"hl.dsp.workspace.toggle_special({argument})"
    if bind.action == "window.move":
        return f"hl.dsp.window.move({{ workspace = {argument} }})"

    raise AssertionError(f"Acción sin renderer: {bind.action}")


def render_lua(binds: list[Bind]) -> str:
    lines = [
        "-- Cachy-caOS managed keybindings",
        "-- AUTOGENERATED: no editar manualmente.",
        "-- Fuente: modules/keybinds/data/binds.toml",
        "",
    ]

    current_category: str | None = None

    for bind in binds:
        if not bind.enabled:
            continue

        if bind.category != current_category:
            if current_category is not None:
                lines.append("")

            lines.append(f"-- {bind.category}")
            current_category = bind.category

        dispatcher = render_dispatcher(bind)

        options = [
            (
                "        description = "
                f"{lua_quote(bind.description)},"
            ),
        ]

        if bind.locked:
            options.append("        locked = true,")

        if bind.mouse:
            options.append("        mouse = true,")

        if bind.event == "release":
            options.append("        release = true,")
            options.append("        repeating = false,")
        elif bind.event == "repeat":
            options.append("        repeating = true,")
        elif bind.event == "long_press":
            options.append("        long_press = true,")
            options.append("        repeating = false,")
        else:
            options.append("        repeating = false,")

        lines.extend(
            [
                "hl.bind(",
                f"    {lua_quote(bind.combo)},",
                f"    {dispatcher},",
                "    {",
                *options,
                "    }",
                ")",
            ]
        )

    lines.extend(["", "return true", ""])

    return "\n".join(lines)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        dir=path.parent,
        text=True,
    )

    temporary = Path(temporary_name)

    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())

        temporary.chmod(0o644)
        temporary.replace(path)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def install_file(
    build: Path,
    target: Path,
    backups: Path,
) -> Path | None:
    backup: Path | None = None

    if target.exists():
        backups.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        backup = backups / f"keybinds-{stamp}.lua"
        shutil.copy2(target, backup)

    atomic_write(
        target,
        build.read_text(encoding="utf-8"),
    )

    return backup


def restore_install(target: Path, backup: Path | None) -> None:
    if backup is None:
        target.unlink(missing_ok=True)
        return

    atomic_write(target, backup.read_text(encoding="utf-8"))


def latest_backup(backups: Path) -> Path:
    candidates = sorted(backups.glob("keybinds-*.lua"))

    if not candidates:
        fail(f"No hay respaldos en {backups}.")

    return candidates[-1]


def show_plan(target: Path, content: str) -> bool:
    previous = ""

    if target.exists():
        previous = target.read_text(encoding="utf-8")

    if previous == content:
        print("✓ Sin cambios pendientes")
        return False

    diff = difflib.unified_diff(
        previous.splitlines(keepends=True),
        content.splitlines(keepends=True),
        fromfile=str(target),
        tofile=f"{target} (propuesto)",
    )
    sys.stdout.writelines(diff)
    return True


def extract_generated_combos(content: str) -> set[str]:
    pattern = re.compile(
        r'hl\.bind\(\s*"((?:\\.|[^"\\])*)"\s*,',
        re.MULTILINE,
    )
    combos: set[str] = set()

    for match in pattern.finditer(content):
        encoded = match.group(1)
        combo = (
            encoded
            .replace(r"\n", "\n")
            .replace(r"\"", '"')
            .replace(r"\\", "\\")
        )
        combos.add(combo)

    return combos


def eval_failed(result: subprocess.CompletedProcess[str]) -> bool:
    message = "\n".join((result.stdout, result.stderr))
    error_line = any(
        line.strip().lower().startswith(("error", "failed"))
        for line in message.splitlines()
    )
    return result.returncode != 0 or error_line


def reconcile_hyprland(
    previous_content: str,
    current_content: str,
    load_module: bool = True,
) -> tuple[bool, str]:
    combos = sorted(
        extract_generated_combos(previous_content)
        | extract_generated_combos(current_content)
    )
    statements = [
        f"hl.unbind({lua_quote(combo)})"
        for combo in combos
    ]

    if load_module:
        statements.extend(
            [
                f"package.loaded[{lua_quote(LUA_MODULE)}] = nil",
                f"require({lua_quote(LUA_MODULE)})",
            ]
        )

    if statements:
        eval_result = run_command(
            ["hyprctl", "eval", "\n".join(statements)]
        )

        if eval_failed(eval_result):
            return False, eval_result.stderr or eval_result.stdout

    errors = run_command(["hyprctl", "configerrors"])
    message = errors.stderr or errors.stdout

    if errors.returncode != 0 or errors.stdout.strip():
        return False, message

    return True, ""


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=False,
        text=True,
        capture_output=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Genera keybinds.lua desde binds.toml."
    )
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--build", type=Path, default=DEFAULT_BUILD)
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    parser.add_argument(
        "--backups",
        type=Path,
        default=DEFAULT_BACKUPS,
    )
    parser.add_argument(
        "--install",
        action="store_true",
        help="Instala el archivo generado en Hyprland.",
    )
    parser.add_argument(
        "--reload",
        action="store_true",
        help="Recarga Hyprland después de instalar.",
    )
    parser.add_argument(
        "--plan",
        action="store_true",
        help="Muestra los cambios sin instalarlos.",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Comprueba que el destino coincide con el manifiesto.",
    )
    parser.add_argument(
        "--rollback",
        nargs="?",
        const="latest",
        metavar="BACKUP",
        help="Restaura un respaldo o el último disponible.",
    )

    args = parser.parse_args()

    if args.reload and not (args.install or args.rollback):
        print(
            "Error: --reload requiere --install.",
            file=sys.stderr,
        )
        return 1

    try:
        if args.rollback:
            backup = (
                latest_backup(args.backups)
                if args.rollback == "latest"
                else Path(args.rollback).expanduser()
            )

            if not backup.is_file():
                fail(f"Respaldo inexistente: {backup}")

            previous_content = (
                args.target.read_text(encoding="utf-8")
                if args.target.exists()
                else ""
            )
            current_backup = install_file(
                backup,
                args.target,
                args.backups,
            )
            restored_content = args.target.read_text(encoding="utf-8")
            print(f"✓ Respaldo restaurado: {backup}")

            if current_backup:
                print(f"✓ Estado anterior preservado: {current_backup}")

            if args.reload:
                valid, message = reconcile_hyprland(
                    previous_content,
                    restored_content,
                )

                if not valid:
                    restore_install(args.target, current_backup)
                    reconcile_hyprland(
                        restored_content,
                        previous_content,
                        load_module=bool(previous_content),
                    )
                    fail(
                        "Hyprland rechazó el rollback; se restauró "
                        f"el estado previo.\n{message.strip()}"
                    )

                print("✓ Runtime de Hyprland reconciliado sin errores")

            return 0

        binds = load_binds(args.data)
        content = render_lua(binds)
        atomic_write(args.build, content)

        enabled_count = sum(bind.enabled for bind in binds)

        print(f"✓ TOML válido: {len(binds)} registros")
        print(f"✓ Atajos habilitados: {enabled_count}")
        print(f"✓ Lua generado: {args.build}")

        if args.plan:
            show_plan(args.target, content)

        if args.verify:
            if not args.target.exists():
                fail(f"El destino no existe: {args.target}")

            installed = args.target.read_text(encoding="utf-8")

            if installed != content:
                show_plan(args.target, content)
                fail("El archivo instalado no coincide con el manifiesto.")

            print("✓ Destino sincronizado con el manifiesto")

        backup = None
        previous_content = (
            args.target.read_text(encoding="utf-8")
            if args.target.exists()
            else ""
        )

        if args.install:
            backup = install_file(
                args.build,
                args.target,
                args.backups,
            )

            print(f"✓ Lua instalado: {args.target}")

            if backup:
                print(f"✓ Respaldo: {backup}")

        if args.reload:
            valid, message = reconcile_hyprland(
                previous_content,
                content,
            )

            if not valid:
                restore_install(args.target, backup)
                reconcile_hyprland(
                    content,
                    previous_content,
                    load_module=bool(previous_content),
                )
                fail(
                    "Hyprland rechazó el cambio; se restauró "
                    f"automáticamente el estado previo.\n{message.strip()}"
                )

            print("✓ Runtime de Hyprland reconciliado sin errores")

    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
