#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSION="$ROOT/extension"

python3 -m json.tool "$EXTENSION/manifest.json" >/dev/null
node --check "$EXTENSION/background.js"
node --check "$EXTENSION/popup.js"
node --check "$EXTENSION/router-core.mjs"
node --test "$ROOT/tests/router-core.test.mjs"

echo "✓ WebApp Router: validaciones completadas"
