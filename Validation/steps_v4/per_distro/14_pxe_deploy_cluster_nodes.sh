#!/usr/bin/env bash
# PXE-deploy login1, c001 and c002 from the mgmt VM. These VMs have a single
# NIC on the cluster network and boot entirely from the mgmt VM's DHCP/PXE.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

deploy_node() {
    local node=$1
    local mac=$2

    log "  Deploying $node (MAC=$mac) ..."
    destroy_vm "$node"

    # 12000M for the installation (large installer initrds), 4000M after.
    # --wait 0: start the installation and return, nodes install in parallel.
    virt-install \
        --name "$node" \
        --os-variant "${DISTRO_OS_VARIANT[$distro]}" \
        --ram 12000 \
        --vcpus 2 \
        --disk path="$IMAGES_DIR/$node.qcow2",size=15,bus=virtio,format=qcow2 \
        --network network="$CLUSTER_NETWORK",mac="$mac",model=virtio \
        --pxe \
        --serial pty,log.file="$IMAGES_DIR/$node-serial.log" \
        --graphics vnc,listen=127.0.0.1 \
        $(firmware_flags "$distro") \
        --noautoconsole \
        --noreboot \
        --wait 0
}

if (( STEP < 14 )); then
    log "14 [$distro] PXE-deploy cluster nodes (login1, c001, c002)."

    deploy_node login1 "$CLUSTER_LOGIN1_MAC"
    deploy_node c001   "$CLUSTER_C001_MAC"
    deploy_node c002   "$CLUSTER_C002_MAC"

    # Each node powers off at the end of its installation (--noreboot): wait
    # for that, then boot it on disk with its runtime memory. 2 hours: their
    # internet traffic goes through the capped mgmt VM uplink.
    log "  Waiting for the 3 installations to end (2 hours max) ..."
    for node in login1 c001 c002; do
        for i in $(seq 1 720); do
            [ "$(virsh domstate "$node")" == "shut off" ] && break
            sleep 10
        done
        if [ "$(virsh domstate "$node")" != "shut off" ]; then
            log "  $node installation did not finish. Look at: virsh screenshot $node /tmp/$node.png"
            exit 1
        fi
        virsh setmem "$node" 4000M --config
        virsh start "$node"
        log "  $node installed, booting on disk."
    done

    for node in login1 c001 c002; do
        $SSH_MGMT "timeout 600 /usr/local/bin/waitforssh.sh bluebanquise@$node"
        log "  $node is up."
    done

    log "  All cluster nodes ready."
    STEP=14
fi
