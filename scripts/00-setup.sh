#!/usr/bin/env bash
# Start DVWA and print the addresses you need. Authorized, isolated lab use only.
set -euo pipefail
cd "$(dirname "$0")/.."

# ---- Docker preflight (friendly guidance instead of a raw error) ------------
if ! command -v docker >/dev/null 2>&1; then
  echo "[!!] 'docker' is not installed."
  echo "     Windows/WSL (Ubuntu): run ./scripts/install-ubuntu.sh  (installs Docker + tools)"
  echo "     macOS:                install OrbStack or Docker Desktop, then launch it"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[!!] The Docker daemon is not reachable. The CLI is installed but nothing is running."
  if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    echo "     You're on WSL. Start the Docker Engine inside this distro:"
    echo "         sudo service docker start      # then re-run this script"
    echo "     First time? If it fails to start, see 'Docker on WSL' in the lab manual"
    echo "     (usually: switch to legacy iptables, add yourself to the docker group)."
    echo "     Or just run:  ./scripts/install-ubuntu.sh"
  else
    echo "     macOS: launch OrbStack or Docker Desktop and wait for it to go green."
    echo "         open -a OrbStack    # or: open -a Docker"
  fi
  exit 1
fi

# docker compose (v2 plugin) or docker-compose (v1)?
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "[!!] No Docker Compose found."
  echo "     Ubuntu/WSL:  sudo apt install -y docker-compose-v2"
  exit 1
fi

# ---- Start the target -------------------------------------------------------
echo "[*] Starting DVWA container ($COMPOSE)..."
$COMPOSE up -d

echo "[*] Waiting ~15s for MySQL to warm up..."
sleep 15

echo
echo "[*] DVWA:  http://localhost:42080"
echo "    Login admin / password, then click 'Create / Reset Database', then log in again."
echo
echo "[*] Container IP (use as RHOST with port 80 if you scan it directly):"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa 2>/dev/null || true

echo "[*] LHOST hint (the address the TARGET calls back to):"
if command -v ip >/dev/null 2>&1 && ip -4 addr show docker0 >/dev/null 2>&1; then
  # Linux / WSL / Kali with Docker running INSIDE the distro: the docker0 bridge gateway.
  gw=$(ip -4 addr show docker0 | awk '/inet /{print $2}' | cut -d/ -f1)
  echo "    Linux/WSL docker0 gateway -> ${gw:-172.17.0.1}"
  echo "    (set LHOST=$gw in lab.env)"
else
  # macOS + Docker Desktop / OrbStack: the container reaches the host via
  # host.docker.internal; print what that resolves to INSIDE the container.
  hdi=$(docker exec dvwa getent hosts host.docker.internal 2>/dev/null | awk '{print $1}')
  echo "    macOS (Docker Desktop/OrbStack) -> ${hdi:-host.docker.internal}"
  echo "    (set this as LHOST in lab.env; the handlers already bind 0.0.0.0)"
fi
echo
echo "[*] Next: set LHOST in lab.env, then ./scripts/10-payloads.sh"
