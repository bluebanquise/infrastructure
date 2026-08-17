#!/usr/bin/env bash
# Create virbr1 (private_network) and virbr2 (cluster_network) if not present,
# and ensure both are active (a defined-but-inactive network has no bridge on the host).
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ensure_network() {
    local net=$1
    local xml=$2

    # Define if missing entirely.
    if ! virsh net-list --all 2>/dev/null | grep -qw "$net"; then
        log "  Defining $net ..."
        virsh net-define "$xml"
        virsh net-autostart "$net"
    fi

    # Start if not active (active networks appear in net-list without --all).
    if ! virsh net-list 2>/dev/null | grep -qw "$net"; then
        log "  Starting $net ..."
        virsh net-start "$net"
    fi
}

if (( STEP < 1 )); then
    log "01 Setup networks."

    ensure_network private_network "$CURRENT_DIR/../vms/private_network.xml"
    ensure_network cluster_network "$CURRENT_DIR/../vms/cluster_network.xml"

    # Give the kernel a moment to bring up both bridge interfaces.
    sleep 2

    log "  virbr1: $(ip link show virbr1 2>&1 | head -1)"
    log "  virbr2: $(ip link show virbr2 2>&1 | head -1)"
    log "  Networks ready."
    STEP=1
fi
