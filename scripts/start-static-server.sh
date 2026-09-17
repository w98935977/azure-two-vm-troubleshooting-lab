#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="${LAB_DIR:-$HOME/lab-http}"
PORT="${PORT:-8080}"
BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0}"

mkdir -p "$LAB_DIR"
printf 'vm-linux-02 lab service is healthy\n' > "$LAB_DIR/index.html"

nohup python3 -m http.server "$PORT" \
  --bind "$BIND_ADDRESS" \
  --directory "$LAB_DIR" \
  >/tmp/lab-http.log 2>&1 &

echo $! | sudo tee /run/lab-http.pid >/dev/null
echo "Started static server on ${BIND_ADDRESS}:${PORT} (PID $!)"

