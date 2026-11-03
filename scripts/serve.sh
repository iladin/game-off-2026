#!/usr/bin/env bash
# Serve build/web on http://localhost:8000 (after ./scripts/export_web.sh).
cd "$(dirname "$0")/../build/web" && python3 -m http.server "${1:-8000}"
