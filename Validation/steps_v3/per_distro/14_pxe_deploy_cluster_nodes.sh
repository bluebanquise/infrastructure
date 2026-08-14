#!/usr/bin/env bash
# PXE-deploy login1, c001, and c002 from the per-distro mgmt VM via virbr2.
# These VMs have only one NIC (virbr2) and boot entirely from the mgmt VM's
# DHCP/PXE stack.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

OS_VARIANT=${DISTRO_OS_VARIANT[$distro]}
BOOT_FLAGS=${DISTRO_BOOT_FLAGS[$distro]}
UNDEFINE_FLAGS=${DISTRO_UNDEFINE_FLAGS[$distro]}
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

deploy_node() {
    local node=$1
    local mac=$2
    local ip=$3

    log "  Deploying $node (MAC=$mac, IP=$ip) ..."

    virsh destroy "$node" 2>/dev/null && log "    Destroyed existing $node." || true
    virsh undefine "$node" $UNDEFINE_FLAGS 2>/dev/null && log "    Undefined existing $node." || true
    sudo rm -f /var/lib/libvirt/images/"$node".qcow2

    virt-install \
        --name="$node" \
        --os-variant="$OS_VARIANT" \
        --ram=12000 \
        --vcpus=2 \
        --noreboot \
        --disk path=/var/lib/libvirt/images/"$node".qcow2,bus=virtio,size=15 \
        --network bridge=virbr2,mac="$mac" \
        --pxe \
        $BOOT_FLAGS

    # 12000M was only needed for the install/provisioning boot (--ram above).
    # Drop to 4000M before the disk boot (2026-08-09, explicit request — 12000M
    # is provisioning-only, not a steady-state runtime requirement).
    virsh setmem "$node" 4000M --config
    virsh start "$node"
}

if (( STEP < 14 )); then
    log "14 [$distro] PXE-deploy cluster nodes (login1, c001, c002)."

    # Deploy all three nodes; they install in parallel.
    deploy_node login1 "$CLUSTER_LOGIN1_MAC" "$CLUSTER_LOGIN1_IP"
    deploy_node c001   "$CLUSTER_C001_MAC"   "$CLUSTER_C001_IP"
    deploy_node c002   "$CLUSTER_C002_MAC"   "$CLUSTER_C002_IP"

    log "  Waiting for all cluster nodes to come up (SSH) ..."
    sleep 60

    for node in login1 c001 c002; do
        $SSH_MGMT "ssh-keygen -f /var/lib/bluebanquise/.ssh/known_hosts -R $node 2>/dev/null || true"
        $SSH_MGMT "/usr/local/bin/waitforssh.sh bluebanquise@$node"
        log "  $node is up."
    done

    log "  All cluster nodes ready."
    STEP=14
fi
