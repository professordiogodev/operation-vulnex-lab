#!/usr/bin/env bash
# Phase 0 recon. Plain nmap for the service scan, then Metasploit HTTP aux
# modules. No Metasploit database required (works on a stock Homebrew install).
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env

echo "[*] nmap service scan of $RHOST:$RPORT"
nmap -sV -p "$RPORT" "$RHOST" || true

echo
echo "[*] Metasploit HTTP aux modules (results print to screen)."
# setg makes RHOSTS/RPORT persist across 'use' switches (plain 'set' does not).
msfconsole -q -x "\
setg RHOSTS $RHOST; setg RPORT $RPORT; \
use auxiliary/scanner/http/http_version; run; \
use auxiliary/scanner/http/robots_txt; run; \
use auxiliary/scanner/http/dir_scanner; run; \
exit"
