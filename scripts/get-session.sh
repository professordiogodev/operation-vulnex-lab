#!/usr/bin/env bash
# Log into DVWA as admin/password, set security to Low, and print a live
# PHPSESSID. Saves you from digging through browser devtools.
# Usage:  ./scripts/get-session.sh            # prints PHPSESSID
#         SID=$(./scripts/get-session.sh)     # capture into a variable
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env
B="http://$RHOST:$RPORT"
J="$(mktemp)"; trap 'rm -f "$J"' EXIT

tok(){ grep -oE "user_token' value='[a-f0-9]{32}" | grep -oE "[a-f0-9]{32}"; }

t=$(curl -s -c "$J" "$B/login.php" | tok)
curl -s -b "$J" -c "$J" -o /dev/null \
  --data "username=admin&password=password&user_token=$t&Login=Login" "$B/login.php"
st=$(curl -s -b "$J" -c "$J" "$B/security.php" | tok)
curl -s -b "$J" -c "$J" -o /dev/null \
  --data "security=low&seclev_submit=Submit&user_token=$st" "$B/security.php"

SID=$(grep PHPSESSID "$J" | awk '{print $7}')
if [ -z "$SID" ]; then
  echo "[!] Could not get a session. Is DVWA up (./scripts/00-setup.sh) and the DB created?" >&2
  exit 1
fi
# Human hint on stderr, raw value on stdout (so $(...) capture stays clean).
echo "[*] Logged in admin/password, security=low. PHPSESSID below:" >&2
echo "$SID"
