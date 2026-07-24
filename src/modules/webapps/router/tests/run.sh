#!/usr/bin/env bash

set -euo pipefail

export PYTHONDONTWRITEBYTECODE=1

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSION="$ROOT/extension"

python3 -m json.tool "$EXTENSION/manifest.json" >/dev/null
node --check "$EXTENSION/background.js"
node --check "$EXTENSION/popup.js"
node --check "$EXTENSION/router-core.mjs"
node --test "$ROOT/tests/router-core.test.mjs"
python3 "$ROOT/tests/registry.test.py"
bash "$ROOT/tests/install.test.sh"

echo "✓ WebApp Router: validaciones completadas"
