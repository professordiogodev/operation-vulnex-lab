#!/usr/bin/env bash
# Reset DVWA between students/runs.
set -euo pipefail
cd "$(dirname "$0")/.."
docker restart dvwa
echo "[*] DVWA restarted. In the browser, click 'Create / Reset Database' to wipe uploads and reset users."
echo "[*] Full teardown instead:  docker compose down"
