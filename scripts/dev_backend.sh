#!/usr/bin/env bash
# Run the Django backend locally for development.
set -euo pipefail
cd "$(dirname "$0")/../backend"
../venv/bin/python manage.py migrate
exec ../venv/bin/python manage.py runserver 127.0.0.1:8000
