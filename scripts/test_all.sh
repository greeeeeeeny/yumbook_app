#!/usr/bin/env bash
# Run backend tests + frontend analyze.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Django tests"
(cd "$ROOT/backend" && "$ROOT/venv/bin/python" manage.py test reservations)

echo "==> Flutter analyze"
export PATH="$ROOT/.flutter-sdk/flutter/bin:$PATH"
(cd "$ROOT/frontend" && flutter analyze lib/)
