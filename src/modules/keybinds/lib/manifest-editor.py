#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import sys
import tempfile
import tomllib
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Any


MODULE_DIR = Path.home() / ".local/share/cachycaos/modules/keybinds"
DEFAULT_DATA = MODULE_DIR / "data/binds.toml"
DEFAULT_INVENTORY = MODULE_DIR / "cache/enriched.tsv"
DEFAULT_BACKUPS = MODULE_DIR / "backups"
DEFAULT_TARGET = Path.home() / ".config/hypr/cachycaos/keybinds.lua"

MODIFIER_ORDER = ("SUPER", "CTRL", "ALT", "SHIFT")
VALID_EVENTS = {"press", "release", "repeat"}
STATIC_ACTIONS = {
    "window.close",
    "window.float.toggle",
    "window.pseudo",
    "window.fullscreen",
    "window.drag",
    "window.resize",
}
ARGUMENT_ACTIONS = {
    "exec",
    "layout",
    "focus",
    "workspace.focus",
    "workspace.special",
    "window.move",
}
VALID_ACTIONS = STATIC_ACTIONS | ARGUMENT_ACTIONS

KEY_ALIASES = {
    "SUBIR VOLUMEN": "XF86AudioRaiseVolume",
    "BAJAR VOLUMEN": "XF86AudioLowerVolume",
    "SILENCIAR AUDIO": "XF86AudioMute",
    "SILENCIAR MICRÓFONO": "XF86AudioMicMute",
    "SUBIR BRILLO": "XF86MonBrightnessUp",
    "BAJAR BRILLO": "XF86MonBrightnessDown",
    "SIGUIENTE PISTA": "XF86AudioNext",
    "PISTA ANTERIOR": "XF86AudioPrev",
    "REPRODUCIR": "XF86AudioPlay",
    "PAUSA": "XF86AudioPause",
    "RUEDA ABAJO": "mouse_down",
    "RUEDA ARRIBA": "mouse_up",
    "CLIC IZQUIERDO": "mouse:272",
    "CLIC DERECHO": "mouse:273",
    "CLIC CENTRAL": "mouse:274",
}

CATEGORY_PREFIXES = {
    "aplicaciones": "apps",
    "audio": "media",
    "escritorios": "workspaces",
    "general": "general",
    "multimedia": "media",
    "sistema": "system",
    "ventanas": "windows",
    "workspaces": "workspaces",
}


def fail(message: str) -> None:
    raise ValueError(message)


def toml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def as_bool(value: Any, field: str) -> bool:
    if not isinstance(value, bool):
        fail(f"'{field}' debe ser true o false.")
    return value


def normalize_modifiers(values: list[str]) -> list[str]:
    normalized: list[str] = []

    for value in values:
        modifier = value.strip().upper()
        modifier = {"CONTROL": "CTRL", "MOD4": "SUPER"}.get(
            modifier,
            modifier,
        )

        if modifier not in MODIFIER_ORDER:
            fail(f"Modificador desconocido: {value}")

        if modifier not in normalized:
            normalized.append(modifier)

    return [item for item in MODIFIER_ORDER if item in normalized]


def parse_combo(combo: str) -> tuple[list[str], str]:
    parts = [part.strip() for part in combo.split("+") if part.strip()]
    modifiers: list[str] = []
    key_parts: list[str] = []

    for part in parts:
        upper = part.upper()
        alias = {"CONTROL": "CTRL", "MOD4": "SUPER"}.get(upper, upper)

        if alias in MODIFIER_ORDER:
            modifiers.append(alias)
        else:
            key_parts.append(part)

    if not key_parts:
        fail(f"La combinación no contiene una tecla: {combo}")

    key = " + ".join(key_parts)
    key = KEY_ALIASES.get(key.upper(), key)
    return normalize_modifiers(modifiers), key


def combo_for(record: dict[str, Any]) -> str:
    modifiers_raw = record.get("modifiers", [])
    if not isinstance(modifiers_raw, list) or not all(
        isinstance(item, str) for item in modifiers_raw
    ):
        fail("'modifiers' debe ser una lista de textos.")
    modifiers = normalize_modifiers(modifiers_raw)
    return " + ".join([*modifiers, str(record["key"])])


def canonical_combo(combo: str) -> str:
    modifiers, key = parse_combo(combo)
    return " + ".join([*modifiers, key.upper()])


def slugify(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value)
    ascii_value = "".join(
        character for character in decomposed
        if not unicodedata.combining(character)
    )
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_value.lower()).strip("-")
    return slug or "atajo"


def identifier_for(
    category: str,
    combo: str,
    used_identifiers: set[str],
) -> str:
    category_slug = slugify(category or "General")
    prefix = CATEGORY_PREFIXES.get(category_slug, category_slug)
    base = f"{prefix}.{slugify(combo)}"
    candidate = base
    suffix = 2

    while candidate in used_identifiers:
        candidate = f"{base}-{suffix}"
        suffix += 1

    used_identifiers.add(candidate)
    return candidate


def normalize_action(action: str) -> str:
    aliases = {
        "window.float": "window.float.toggle",
    }
    normalized = aliases.get(action, action)

    if normalized not in VALID_ACTIONS:
        fail(
            f"La acción '{action}' todavía no puede ser administrada "
            "por N.E.S.T."
        )

    return normalized


def validate_record(record: dict[str, Any], number: int) -> None:
    for field in ("id", "key", "category", "description", "action"):
        value = record.get(field)

        if not isinstance(value, str) or not value.strip():
            fail(f"bind #{number}: '{field}' debe ser texto no vacío.")

    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", record["id"]):
        fail(
            f"bind #{number}: ID no válido '{record['id']}'. "
            "Usa minúsculas, números, puntos, guiones o guion bajo."
        )

    as_bool(record.get("enabled", True), "enabled")
    as_bool(record.get("locked", False), "locked")
    as_bool(record.get("mouse", False), "mouse")
    modifiers_raw = record.get("modifiers", [])
    if not isinstance(modifiers_raw, list) or not all(
        isinstance(item, str) for item in modifiers_raw
    ):
        fail(f"bind #{number}: 'modifiers' debe ser una lista de textos.")
    normalize_modifiers(modifiers_raw)

    event = record.get("event", "press")
    if event not in VALID_EVENTS:
        fail(f"bind #{number}: evento desconocido '{event}'.")

    action = normalize_action(record["action"])
    argument = record.get("argument")

    if action in ARGUMENT_ACTIONS:
        if not isinstance(argument, str) or not argument.strip():
            fail(f"bind #{number}: '{action}' requiere argument.")
    elif argument is not None:
        fail(f"bind #{number}: '{action}' no acepta argument.")


def validate_document(records: list[dict[str, Any]]) -> None:
    identifiers: set[str] = set()
    enabled_combos: set[str] = set()
    imported_identities: set[str] = set()

    for number, record in enumerate(records, start=1):
        validate_record(record, number)

        identifier = record["id"]
        if identifier in identifiers:
            fail(f"ID duplicado: {identifier}")
        identifiers.add(identifier)

        imported_identity = record.get("imported_identity")
        if imported_identity:
            if not isinstance(imported_identity, str):
                fail(f"bind #{number}: 'imported_identity' debe ser texto.")
            if imported_identity in imported_identities:
                fail(f"Origen importado duplicado: {imported_identity}")
            imported_identities.add(imported_identity)

        if record.get("enabled", True):
            combo = canonical_combo(combo_for(record))
            if combo in enabled_combos:
                fail(f"Combinación habilitada duplicada: {combo}")
            enabled_combos.add(combo)


def load_document(path: Path) -> list[dict[str, Any]]:
    with path.open("rb") as handle:
        document = tomllib.load(handle)

    if document.get("version") != 1:
        fail("El manifiesto debe declarar version = 1.")

    records = document.get("bind", [])
    if not isinstance(records, list):
        fail("'bind' debe ser una lista TOML.")

    copied = [dict(record) for record in records]
    validate_document(copied)
    return copied


def render_document(records: list[dict[str, Any]]) -> str:
    lines = ["version = 1", ""]

    for record in records:
        lines.append("[[bind]]")
        lines.append(f"id = {toml_string(record['id'])}")
        lines.append(
            f"enabled = {'true' if record.get('enabled', True) else 'false'}"
        )
        modifiers = normalize_modifiers(record.get("modifiers", []))
        rendered_modifiers = ", ".join(toml_string(item) for item in modifiers)
        lines.append(f"modifiers = [{rendered_modifiers}]")
        lines.append(f"key = {toml_string(record['key'])}")
        lines.append(f"category = {toml_string(record['category'])}")
        lines.append(f"description = {toml_string(record['description'])}")
        lines.append(f"action = {toml_string(normalize_action(record['action']))}")

        if record.get("argument") is not None:
            lines.append(f"argument = {toml_string(record['argument'])}")

        lines.append(f"event = {toml_string(record.get('event', 'press'))}")
        lines.append(
            f"locked = {'true' if record.get('locked', False) else 'false'}"
        )
        lines.append(
            f"mouse = {'true' if record.get('mouse', False) else 'false'}"
        )

        if record.get("imported_from"):
            lines.append(
                f"imported_from = {toml_string(record['imported_from'])}"
            )
        if record.get("imported_line") is not None:
            lines.append(f"imported_line = {int(record['imported_line'])}")
        if record.get("imported_identity"):
            lines.append(
                f"imported_identity = {toml_string(record['imported_identity'])}"
            )

        lines.append("")

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


def save_document(
    path: Path,
    backups: Path,
    records: list[dict[str, Any]],
) -> Path:
    validate_document(records)
    backups.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup = backups / f"binds-{stamp}.toml"
    shutil.copy2(path, backup)
    atomic_write(path, render_document(records))
    return backup


def find_record(records: list[dict[str, Any]], identifier: str) -> dict[str, Any]:
    for record in records:
        if record["id"] == identifier:
            return record
    fail(f"No existe el binding '{identifier}'.")


def read_inventory(path: Path) -> list[list[str]]:
    if not path.is_file():
        fail(f"No existe el inventario: {path}")

    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))

    for number, row in enumerate(rows, start=1):
        if len(row) != 12:
            fail(f"{path}:{number}: inventario incompatible.")
    return rows


def is_managed_origin(origin: str, managed_target: Path) -> bool:
    try:
        return (
            Path(origin).expanduser().resolve()
            == managed_target.expanduser().resolve()
        )
    except OSError:
        return False


def conflicts_for(
    records: list[dict[str, Any]],
    inventory: Path,
    managed_target: Path,
) -> list[str]:
    rows = read_inventory(inventory)
    conflicts: list[str] = []

    for record in records:
        if not record.get("enabled", True):
            continue

        expected = canonical_combo(combo_for(record))

        for row in rows:
            runtime_combo = canonical_combo(row[1])
            origin = row[6]

            if runtime_combo != expected:
                continue

            if not is_managed_origin(origin, managed_target):
                conflicts.append(
                    f"{record['id']}: {combo_for(record)} ya existe en "
                    f"{origin or 'runtime'}"
                )

    return sorted(set(conflicts))


def flags_from_text(value: str) -> tuple[str, bool, bool]:
    flags = set(value.split(",")) if value and value != "-" else set()
    event = "release" if "release" in flags else (
        "repeat" if "repeat" in flags else "press"
    )
    return event, "locked" in flags, "mouse" in flags


def import_record(
    rows: list[list[str]],
    identity: str,
    identifier: str,
) -> dict[str, Any]:
    row = next((candidate for candidate in rows if candidate[0] == identity), None)
    if row is None:
        fail(f"No existe la identidad runtime '{identity}'.")

    (
        _identity,
        combo,
        category,
        description,
        action,
        argument,
        origin,
        source_line,
        _dispatcher,
        _runtime_argument,
        submap,
        flags,
    ) = row
    if submap not in {"", "-", "global"}:
        fail(
            f"El submap '{submap}' todavía no puede ser administrado "
            "por N.E.S.T."
        )
    modifiers, key = parse_combo(combo)
    event, locked, mouse = flags_from_text(flags)
    normalized_action = normalize_action(action)

    record: dict[str, Any] = {
        "id": identifier,
        "enabled": False,
        "modifiers": modifiers,
        "key": key,
        "category": category or "General",
        "description": description or f"Importado: {combo}",
        "action": normalized_action,
        "event": event,
        "locked": locked,
        "mouse": mouse,
        "imported_from": origin,
        "imported_identity": identity,
    }

    if normalized_action in ARGUMENT_ACTIONS:
        record["argument"] = argument
    if source_line.isdigit():
        record["imported_line"] = int(source_line)

    validate_record(record, 1)
    return record


def bulk_import_records(
    records: list[dict[str, Any]],
    rows: list[list[str]],
    managed_target: Path,
) -> tuple[list[dict[str, Any]], list[str], list[str]]:
    existing_identities = {
        str(record["imported_identity"])
        for record in records
        if record.get("imported_identity")
    }
    used_identifiers = {str(record["id"]) for record in records}
    imported: list[dict[str, Any]] = []
    skipped: list[str] = []
    errors: list[str] = []

    for row in rows:
        identity, combo, category, *_rest = row
        origin = row[6]

        if is_managed_origin(origin, managed_target):
            skipped.append(f"{combo}: ya administrado por N.E.S.T.")
            continue

        if identity in existing_identities:
            skipped.append(f"{combo}: ya importado")
            continue

        identifier = identifier_for(category, combo, used_identifiers)

        try:
            imported.append(import_record(rows, identity, identifier))
        except ValueError as error:
            errors.append(f"{combo}: {error}")

    if errors:
        fail(
            "La importación masiva fue cancelada; no se modificó nada:\n"
            + "\n".join(errors)
        )

    proposed = [*records, *imported]
    validate_document(proposed)
    return proposed, imported, skipped


def print_bulk_import(
    imported: list[dict[str, Any]],
    skipped: list[str],
    dry_run: bool,
) -> None:
    label = "por importar" if dry_run else "importados"
    print(f"✓ Atajos {label}: {len(imported)}")

    for record in imported:
        print(
            f"  {record['id']}: {combo_for(record)}"
            f" → {record['description']}"
        )

    if skipped:
        print(f"✓ Omitidos de forma segura: {len(skipped)}")
        for message in skipped:
            print(f"  {message}")


def print_records(records: list[dict[str, Any]], output_format: str) -> None:
    if output_format == "json":
        print(json.dumps(records, ensure_ascii=False, indent=2))
        return

    for record in records:
        fields = (
            record["id"],
            "true" if record.get("enabled", True) else "false",
            combo_for(record),
            record["category"],
            record["description"],
            record["action"],
            record.get("argument") or "-",
            record.get("event", "press"),
            "true" if record.get("locked", False) else "false",
            "true" if record.get("mouse", False) else "false",
            record.get("imported_from", "managed"),
            str(record.get("imported_line", "-")),
            record.get("imported_identity") or "-",
        )
        print("\t".join(fields))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Edita de forma segura el manifiesto de Keybinds."
    )
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--backups", type=Path, default=DEFAULT_BACKUPS)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--managed-target", type=Path, default=DEFAULT_TARGET)
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("--format", choices=("tsv", "json"), default="tsv")

    add_parser = subparsers.add_parser("add")
    add_parser.add_argument("--id", required=True)
    add_parser.add_argument("--combo", required=True)
    add_parser.add_argument("--category", required=True)
    add_parser.add_argument("--description", required=True)
    add_parser.add_argument("--action", required=True)
    add_parser.add_argument("--argument")
    add_parser.add_argument("--event", choices=sorted(VALID_EVENTS), default="press")
    add_parser.add_argument("--locked", action="store_true")
    add_parser.add_argument("--mouse", action="store_true")
    add_parser.add_argument("--enabled", action="store_true")

    import_parser = subparsers.add_parser("import")
    import_parser.add_argument("--identity", required=True)
    import_parser.add_argument("--id", required=True)

    import_all_parser = subparsers.add_parser("import-all")
    import_all_parser.add_argument("--dry-run", action="store_true")

    set_parser = subparsers.add_parser("set")
    set_parser.add_argument("--id", required=True)
    set_parser.add_argument("--combo")
    set_parser.add_argument("--category")
    set_parser.add_argument("--description")
    set_parser.add_argument("--action")
    set_parser.add_argument("--argument")
    set_parser.add_argument("--event", choices=sorted(VALID_EVENTS))
    set_parser.add_argument("--locked", choices=("true", "false"))
    set_parser.add_argument("--mouse", choices=("true", "false"))

    for command in ("enable", "disable", "remove"):
        command_parser = subparsers.add_parser(command)
        command_parser.add_argument("--id", required=True)

    subparsers.add_parser("enable-drafts")
    subparsers.add_parser("check-conflicts")
    args = parser.parse_args()

    try:
        records = load_document(args.data)

        if args.command == "list":
            print_records(records, args.format)
            return 0

        if args.command == "check-conflicts":
            conflicts = conflicts_for(records, args.inventory, args.managed_target)
            if conflicts:
                print("\n".join(conflicts), file=sys.stderr)
                return 2
            print("✓ Sin conflictos externos")
            return 0

        if args.command == "import-all":
            rows = read_inventory(args.inventory)
            records, imported, skipped = bulk_import_records(
                records,
                rows,
                args.managed_target,
            )
            print_bulk_import(imported, skipped, args.dry_run)

            if args.dry_run or not imported:
                return 0

            backup = save_document(args.data, args.backups, records)
            print(f"✓ Manifiesto actualizado: {args.data}")
            print(f"✓ Respaldo: {backup}")
            return 0

        if args.command == "enable-drafts":
            drafts = [
                record for record in records
                if not record.get("enabled", True)
            ]

            if not drafts:
                print("✓ No hay borradores deshabilitados")
                return 0

            for record in drafts:
                record["enabled"] = True

            conflicts = conflicts_for(
                records,
                args.inventory,
                args.managed_target,
            )
            if conflicts:
                fail(
                    "No se puede habilitar el lote; "
                    "no se modificó nada:\n"
                    + "\n".join(conflicts)
                )

            backup = save_document(args.data, args.backups, records)
            print(f"✓ Borradores habilitados: {len(drafts)}")
            print(f"✓ Manifiesto actualizado: {args.data}")
            print(f"✓ Respaldo: {backup}")
            return 0

        if args.command == "add":
            modifiers, key = parse_combo(args.combo)
            record: dict[str, Any] = {
                "id": args.id,
                "enabled": args.enabled,
                "modifiers": modifiers,
                "key": key,
                "category": args.category,
                "description": args.description,
                "action": normalize_action(args.action),
                "event": args.event,
                "locked": args.locked,
                "mouse": args.mouse,
            }
            if args.argument is not None:
                record["argument"] = args.argument
            records.append(record)
        elif args.command == "import":
            rows = read_inventory(args.inventory)
            records.append(import_record(rows, args.identity, args.id))
        elif args.command == "set":
            record = find_record(records, args.id)
            if args.combo:
                modifiers, key = parse_combo(args.combo)
                record["modifiers"] = modifiers
                record["key"] = key
            for field in ("category", "description", "action", "argument", "event"):
                value = getattr(args, field)
                if value is not None:
                    record[field] = normalize_action(value) if field == "action" else value
            if args.action is not None:
                normalized_action = normalize_action(args.action)
                if normalized_action in STATIC_ACTIONS and args.argument is None:
                    record.pop("argument", None)
            if args.locked is not None:
                record["locked"] = args.locked == "true"
            if args.mouse is not None:
                record["mouse"] = args.mouse == "true"
        elif args.command in {"enable", "disable"}:
            record = find_record(records, args.id)
            record["enabled"] = args.command == "enable"

            if args.command == "enable":
                conflicts = conflicts_for(records, args.inventory, args.managed_target)
                if conflicts:
                    fail("No se puede habilitar:\n" + "\n".join(conflicts))
        elif args.command == "remove":
            record = find_record(records, args.id)
            records.remove(record)

        backup = save_document(args.data, args.backups, records)
        print(f"✓ Manifiesto actualizado: {args.data}")
        print(f"✓ Respaldo: {backup}")
    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
