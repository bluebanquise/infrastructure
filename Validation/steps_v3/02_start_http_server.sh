#!/usr/bin/env bash
# Start a Python HTTP server on the host to serve ISOs to mgt1.
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( STEP < 2 )); then
    log "02 Start host HTTP server."

    mkdir -p "$CURRENT_DIR/../http"
    cd "$CURRENT_DIR/../http"

    # Kill any existing server on the same port.
    pkill -f "python3 -m http.server $HOST_HTTP_PORT" 2>/dev/null || true
    sleep 1

    python3 -m http.server "$HOST_HTTP_PORT" > "$CURRENT_DIR/../http/http_server.log" 2>&1 &
    export HTTP_SERVER_PID=$!
    log "  HTTP server started (pid $HTTP_SERVER_PID) at http://$HOST_IP:$HOST_HTTP_PORT"

    STEP=2
fi
