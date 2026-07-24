#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any


MODIFIERS = (
    (64, "SUPER"),
    (4, "CTRL"),
    (8, "ALT"),
    (1, "SHIFT"),
)

KEY_NAMES = {
    "XF86AudioRaiseVolume": "SUBIR VOLUMEN",
    "XF86AudioLowerVolume": "BAJAR VOLUMEN",
    "XF86AudioMute": "SILENCIAR AUDIO",
    "XF86AudioMicMute": "SILENCIAR MICRÓFONO",
    "XF86MonBrightnessUp": "SUBIR BRILLO",
    "XF86MonBrightnessDown": "BAJAR BRILLO",
    "XF86AudioNext": "SIGUIENTE PISTA",
    "XF86AudioPrev": "PISTA ANTERIOR",
    "XF86AudioPlay": "REPRODUCIR",
    "XF86AudioPause": "PAUSA",
    "XF86PickupPhone": "CONTESTAR LLAMADA",
    "XF86HangupPhone": "FINALIZAR LLAMADA",
    "mouse_down": "RUEDA ABAJO",
    "mouse_up": "RUEDA ARRIBA",
    "mouse:272": "CLIC IZQUIERDO",
    "mouse:273": "CLIC DERECHO",
    "mouse:274": "CLIC CENTRAL",
    "": "TECLA DESCONOCIDA",
}


@dataclass(frozen=True)
class RuntimeBind:
    directive: str
    modmask: int
    key: str
    keycode: int
    description: str
    dispatcher: str
    argument: str
    submap: str
    locked: bool
    mouse: bool
    release: bool
    repeat: bool
    long_press: bool


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=False,
        text=True,
        capture_output=True,
    )


def as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value

    return str(value).strip().lower() == "true"


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def parse_json(raw: str) -> list[RuntimeBind]:
    document = json.loads(raw)

    if not isinstance(document, list):
        raise ValueError("la raíz JSON no es una lista")

    binds: list[RuntimeBind] = []

    for record in document:
        if not isinstance(record, dict):
            raise ValueError("registro JSON inesperado")

        binds.append(
            RuntimeBind(
                directive="bind",
                modmask=as_int(record.get("modmask")),
                key=str(record.get("key") or ""),
                keycode=as_int(record.get("keycode")),
                description=str(record.get("description") or ""),
                dispatcher=str(record.get("dispatcher") or ""),
                argument=str(record.get("arg") or ""),
                submap=str(record.get("submap") or "global"),
                locked=as_bool(record.get("locked")),
                mouse=as_bool(record.get("mouse")),
                release=as_bool(record.get("release")),
                repeat=as_bool(record.get("repeat")),
                long_press=as_bool(record.get("longPress")),
            )
        )

    return binds


def text_record(
    directive: str,
    fields: dict[str, str],
) -> RuntimeBind:
    suffix = directive.removeprefix("bind")

    return RuntimeBind(
        directive=directive,
        modmask=as_int(fields.get("modmask")),
        key=fields.get("key", ""),
        keycode=as_int(fields.get("keycode")),
        description=fields.get("description", ""),
        dispatcher=fields.get("dispatcher", ""),
        argument=fields.get("arg", ""),
        submap=fields.get("submap", "") or "global",
        locked="l" in suffix,
        mouse="m" in suffix,
        release="r" in suffix,
        repeat="e" in suffix,
        long_press="o" in suffix,
    )


def parse_text(raw: str) -> list[RuntimeBind]:
    binds: list[RuntimeBind] = []
    directive = ""
    fields: dict[str, str] = {}

    def flush() -> None:
        nonlocal directive, fields

        if directive:
            binds.append(text_record(directive, fields))

        directive = ""
        fields = {}

    for raw_line in raw.splitlines():
        line = raw_line.strip()

        if line.startswith("bind") and ":" not in line:
            flush()
            directive = line
            continue

        if not directive or ":" not in line:
            continue

        name, value = line.split(":", 1)
        fields[name.strip()] = value.strip()

    flush()
    return binds


def parse_long_press_flags(raw: str) -> list[bool]:
    """Recover longPress flags from Hyprland's malformed 0.56 JSON.

    Some 0.56 builds emit invalid JSON for `hyprctl binds -j`, but the
    longPress booleans and record order remain intact.  The textual fallback
    contains the correct keys and descriptions, yet omits the long-press
    attribute.  Combining both representations preserves the useful parts of
    each without attempting to repair the corrupted JSON.
    """

    return [
        value == "true"
        for value in re.findall(
            r'"longPress"\s*:\s*(true|false)',
            raw,
        )
    ]


def overlay_long_press_flags(
    binds: list[RuntimeBind],
    flags: list[bool],
) -> tuple[list[RuntimeBind], bool]:
    if not flags or len(flags) != len(binds):
        return binds, False

    return [
        replace(bind, long_press=long_press)
        for bind, long_press in zip(binds, flags, strict=True)
    ], True


def modifier_text(mask: int) -> str:
    parts = [name for bit, name in MODIFIERS if mask & bit]
    return " + ".join(parts) if parts else "SIN MODIFICADOR"


def display_key(bind: RuntimeBind) -> str:
    key = bind.key

    if not key and bind.keycode:
        key = f"code:{bind.keycode}"

    return KEY_NAMES.get(key, key)


def display_combo(bind: RuntimeBind) -> str:
    key = display_key(bind)

    if bind.modmask == 0:
        return key

    return f"{modifier_text(bind.modmask)} + {key}"


def display_flags(bind: RuntimeBind) -> str:
    flags: list[str] = []

    if bind.locked:
        flags.append("locked")
    if bind.mouse:
        flags.append("mouse")
    if bind.release:
        flags.append("release")
    if bind.repeat:
        flags.append("repeat")
    if bind.long_press:
        flags.append("long_press")

    return ",".join(flags) if flags else "-"


def fallback_action(bind: RuntimeBind) -> str:
    if bind.dispatcher and bind.dispatcher != "__lua":
        if bind.argument:
            return f"{bind.dispatcher} · {bind.argument}"
        return bind.dispatcher

    if bind.dispatcher == "__lua":
        return f"Acción Lua interna #{bind.argument or '?'}"

    return "Acción desconocida"


def render(bind: RuntimeBind) -> str:
    flags = display_flags(bind)
    submap = bind.submap or "global"
    key = bind.key or (f"code:{bind.keycode}" if bind.keycode else "")
    identity_source = (
        f"{submap}|{bind.modmask}|{key}|{flags}|{bind.dispatcher}"
    )
    identity = hashlib.sha256(identity_source.encode()).hexdigest()
    action = bind.description or fallback_action(bind)

    columns = (
        identity,
        display_combo(bind),
        action,
        bind.description,
        bind.dispatcher,
        bind.argument,
        submap,
        flags,
    )
    return "\t".join(columns)


def discover(hyprctl: str) -> tuple[list[RuntimeBind], str]:
    json_result = run([hyprctl, "binds", "-j"])
    long_press_flags: list[bool] = []

    if json_result.returncode == 0:
        try:
            return parse_json(json_result.stdout), "json"
        except (json.JSONDecodeError, ValueError):
            long_press_flags = parse_long_press_flags(
                json_result.stdout,
            )

    text_result = run([hyprctl, "binds"])

    if text_result.returncode != 0:
        message = text_result.stderr or text_result.stdout
        raise RuntimeError(message.strip() or "hyprctl binds falló")

    binds = parse_text(text_result.stdout)

    if not binds:
        raise RuntimeError("hyprctl binds no entregó atajos reconocibles")

    binds, recovered_flags = overlay_long_press_flags(
        binds,
        long_press_flags,
    )
    source_format = "text+json-flags" if recovered_flags else "text"
    return binds, source_format


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inventaría los bindings runtime de Hyprland."
    )
    parser.add_argument("--hyprctl", default="hyprctl")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    try:
        binds, source_format = discover(args.hyprctl)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        content = "\n".join(render(bind) for bind in binds) + "\n"
        args.output.write_text(content, encoding="utf-8")
    except (OSError, RuntimeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(
        f"Runtime: {len(binds)} bindings · formato {source_format}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
