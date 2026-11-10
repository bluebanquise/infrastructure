#!/usr/bin/env bash
# Ensure the validation networks exist and are active:
#   - $UPLINK_NETWORK: NAT to internet, the mgmt VM's uplink
#   - $CLUSTER_NETWORK: isolated, the mgmt VM serves DHCP/PXE on it
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ensure_network() {
    local net=$1
    local xml=$2

    # Define if missing entirely.
    if ! virsh net-info "$net" > /dev/null 2>&1; then
        log "  Defining $net ..."
        virsh net-define "$xml"
        virsh net-autostart "$net"
    fi

    # Start if not active (a defined-but-inactive network has no bridge).
    if ! virsh net-info "$net" | grep -qE "^Active: +yes"; then
        log "  Starting $net ..."
        virsh net-start "$net"
    fi
}

if (( STEP < 1 )); then
    log "01 Setup networks."

    ensure_network "$UPLINK_NETWORK" "$CURRENT_DIR/../vms/validation_uplink.xml"
    ensure_network "$CLUSTER_NETWORK" "$CURRENT_DIR/../vms/cluster_network.xml"

    log "  Networks ready."
    STEP=1
fi
