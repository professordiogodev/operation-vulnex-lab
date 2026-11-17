#!/usr/bin/env bash
# Sanity-check the lab environment. Reads state only — exploits nothing.
cd "$(dirname "$0")/.."
ok(){ printf '  [OK] %s\n' "$1"; }
no(){ printf '  [!!] %s\n' "$1"; }

echo "== Tools =="
for t in docker msfconsole msfvenom hydra nmap sqlmap curl; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t"; else no "$t missing"; fi
done

echo "== Docker / DVWA =="
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^dvwa$'; then
  ok "dvwa container running"
else
  no "dvwa not running  (run ./scripts/00-setup.sh)"
fi
code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:42080/login.php 2>/dev/null || echo 000)
if [ "$code" = "200" ]; then ok "DVWA login page reachable (HTTP 200)"; else no "DVWA not reachable on 42080 (got $code)"; fi

echo "== Addresses =="
printf '  container IP   : '; docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa 2>/dev/null || echo '?'
if command -v ip >/dev/null 2>&1 && ip -4 addr show docker0 >/dev/null 2>&1; then
  printf '  docker0 gw     : '; ip -4 addr show docker0 | awk '/inet /{print $2}' | cut -d/ -f1
else
  printf '  LHOST (macOS)  : '; docker exec dvwa getent hosts host.docker.internal 2>/dev/null | awk '{print $1}' || echo '?'
fi

echo "== lab.env =="
if [ -f lab.env ]; then ok "lab.env present"; grep -E '^(LHOST|RHOST|RPORT)=' lab.env; else no "lab.env missing (cp lab.env.example lab.env)"; fi
