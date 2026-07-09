#!/usr/bin/env bash
# Create virbr1 (private_network) and virbr2 (cluster_network) if not present.
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( STEP < 1 )); then
    log "01 Setup networks."

    set +e
    virsh net-list --all | grep -q private_network
    if [ $? -ne 0 ]; then
        set -e
        log "  Creating virbr1 (private_network)."
        virsh net-define "$CURRENT_DIR/../vms/private_network.xml"
        virsh net-start private_network
        virsh net-autostart private_network
    fi

    virsh net-list --all | grep -q cluster_network
    if [ $? -ne 0 ]; then
        set -e
        log "  Creating virbr2 (cluster_network)."
        virsh net-define "$CURRENT_DIR/../vms/cluster_network.xml"
        virsh net-start cluster_network
        virsh net-autostart cluster_network
    fi
    set -e

    log "  Networks ready."
    STEP=1
fi
