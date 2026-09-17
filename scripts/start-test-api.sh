#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

nohup python3 "$SCRIPT_DIR/../app/lab_api.py" >/tmp/lab-api.log 2>&1 &
echo $! | sudo tee /run/lab-http.pid >/dev/null
echo "Started test API on 0.0.0.0:8080 (PID $!)"

