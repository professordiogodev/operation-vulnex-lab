#!/usr/bin/env bash
# One-shot setup for Ubuntu / WSL2 (Ubuntu). Installs Docker + the attacker
# toolkit so the rest of the lab "just works". Safe to re-run.
#
#   ./scripts/install-ubuntu.sh
#
# It uses sudo for system packages and will ask for your password.
set -euo pipefail
cd "$(dirname "$0")/.."

say(){ printf '\n\033[1;36m[*] %s\033[0m\n' "$1"; }
ok(){  printf '    \033[1;32mOK\033[0m %s\n' "$1"; }
warn(){ printf '    \033[1;33m!!\033[0m %s\n' "$1"; }

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer is for Ubuntu/Debian (and Ubuntu on WSL). On macOS use Homebrew;"
  echo "on Kali run:  sudo apt update && sudo apt install -y metasploit-framework nmap hydra sqlmap"
  exit 1
fi

ME="$(id -un)"   # don't rely on $USER — it can be unset under `set -u` on WSL

IS_WSL=0
grep -qiE "microsoft|wsl" /proc/version 2>/dev/null && IS_WSL=1
[ "$IS_WSL" = 1 ] && say "Detected WSL." || say "Detected native Linux."

# ---- 1. System packages -----------------------------------------------------
say "Installing packages (Docker, nmap, hydra, sqlmap, curl)..."
sudo apt-get update -y
sudo apt-get install -y docker.io nmap hydra sqlmap curl ca-certificates gnupg dos2unix
ok "core packages installed"   # gnupg is required for the Metasploit repo key import

# Docker Compose v2 plugin isn't in every Ubuntu release; fall back to v1.
say "Installing Docker Compose..."
if sudo apt-get install -y docker-compose-v2 2>/dev/null; then
  ok "docker compose (v2) installed"
elif sudo apt-get install -y docker-compose 2>/dev/null; then
  ok "docker-compose (v1) installed"
else
  warn "No compose package available via apt — 00-setup will tell you if it's missing"
fi

# ---- 2. WSL/Docker networking: prefer legacy iptables ----------------------
# Docker's bridge networking often fails on WSL/newer Ubuntu with nft tables.
# Switching to the legacy backend is the standard, safe fix.
if update-alternatives --list iptables >/dev/null 2>&1; then
  say "Setting iptables to the legacy backend (fixes Docker networking on WSL)..."
  sudo update-alternatives --set iptables  /usr/sbin/iptables-legacy  || warn "could not set iptables-legacy"
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true
  ok "iptables backend set to legacy"
fi

# ---- 3. Let your user run docker without sudo -------------------------------
say "Adding '$ME' to the docker group..."
sudo groupadd -f docker
sudo usermod -aG docker "$ME"
ok "added (takes effect in a NEW shell, or run: newgrp docker)"

# ---- 4. Start the Docker daemon --------------------------------------------
say "Starting the Docker daemon..."
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files 2>/dev/null | grep -q '^docker\.service'; then
  sudo systemctl enable --now docker 2>/dev/null || sudo service docker start || true
else
  sudo service docker start || true
fi
sleep 3
if sudo docker info >/dev/null 2>&1; then
  ok "Docker daemon is running"
else
  warn "Docker didn't start. On WSL try:  sudo service docker start"
  warn "If it still fails, make sure WSL2 is in use:  wsl -l -v  (VERSION should be 2)"
fi

# ---- 5. Metasploit (not in Ubuntu's repos -> official Rapid7 installer) -----
if command -v msfconsole >/dev/null 2>&1; then
  ok "Metasploit already installed ($(command -v msfconsole))"
else
  say "Installing Metasploit Framework via the official Rapid7 installer..."
  # Rapid7's nightly installer. The script's filename is msfupdate.erb (it adds
  # the apt repo + GPG key, then installs the metasploit-framework package).
  tmp=$(mktemp)
  curl -fsSL "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" -o "$tmp"
  chmod 755 "$tmp"
  sudo "$tmp"
  rm -f "$tmp"
  command -v msfconsole >/dev/null 2>&1 && ok "Metasploit installed" || warn "Metasploit install may have failed — see the manual"
fi

# ---- 6. Normalise this kit (CRLF + exec bits, in case it came from Windows) --
say "Normalising kit scripts (line endings + exec bits)..."
dos2unix -q scripts/*.sh lab.env* 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
ok "kit ready"

cat <<EOF

============================================================
  Done. One important thing:

  The 'docker' group only applies to NEW shells. Either:
     - close and reopen your WSL terminal, or
     - run:  newgrp docker

  Then start the lab:
     cp lab.env.example lab.env      # LHOST default (172.17.0.1) is right for WSL
     ./scripts/00-setup.sh
     ./scripts/90-verify.sh
============================================================
EOF
