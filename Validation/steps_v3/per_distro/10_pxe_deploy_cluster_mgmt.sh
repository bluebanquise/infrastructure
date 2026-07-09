#!/usr/bin/env bash
# PXE-deploy the per-distro cluster management VM from mgt1.
# mgt1's BlueBanquise serves DHCP/PXE on virbr1 for this VM.
# The VM gets two NICs: virbr1 (bootstrap) and virbr2 (cluster).

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

VM_NAME=${DISTRO_VM_NAME[$distro]}
MGMT_IP=${DISTRO_MGMT_VIRBR1_IP[$distro]}
MAC_VIRBR1=${DISTRO_MGMT_MAC_VIRBR1[$distro]}
MAC_VIRBR2=${DISTRO_MGMT_MAC_VIRBR2[$distro]}
ISO_NAME=${DISTRO_ISO_NAME[$distro]}
ISO_URL=${DISTRO_ISO_URL[$distro]}
OS_VARIANT=${DISTRO_OS_VARIANT[$distro]}
BOOT_FLAGS=${DISTRO_BOOT_FLAGS[$distro]}
UNDEFINE_FLAGS=${DISTRO_UNDEFINE_FLAGS[$distro]}
INITIAL_USER=${DISTRO_INITIAL_USER[$distro]}
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if (( STEP < 10 )); then
    log "10 [$distro] PXE-deploy $VM_NAME via mgt1."

    # Download ISO to host http/ cache.
    ISO_PATH="$CURRENT_DIR/../../http/$ISO_NAME"
    if [ ! -f "$ISO_PATH" ]; then
        log "  Downloading $ISO_NAME ..."
        wget -nc -P "$CURRENT_DIR/../../http/" "$ISO_URL"
    fi

    # Transfer ISO to mgt1 (fetched from host HTTP server).
    log "  Transferring ISO to mgt1 ..."
    $SSH_MGT1 "wget -q -nc http://$HOST_IP:$HOST_HTTP_PORT/$ISO_NAME -P /var/lib/bluebanquise/"

    # Mount ISO and run bluebanquise-bootset on mgt1 to set up PXE for this node.
    log "  Setting up PXE on mgt1 for $VM_NAME ..."
    $SSH_MGT1 << EOF
set -e
PYTHONPATH=\$(pip3 show ClusterShell 2>/dev/null | grep Location | awk '{print \$2}')
case "$distro" in
    rhel9)
        sudo mkdir -p /var/www/html/pxe/netboots/redhat/9/x86_64/iso
        sudo mount /var/lib/bluebanquise/$ISO_NAME /var/www/html/pxe/netboots/redhat/9/x86_64/iso 2>/dev/null || true
        ;;
    rhel10)
        sudo mkdir -p /var/www/html/pxe/netboots/redhat/10/x86_64/iso
        sudo mount /var/lib/bluebanquise/$ISO_NAME /var/www/html/pxe/netboots/redhat/10/x86_64/iso 2>/dev/null || true
        ;;
    ubuntu24)
        sudo mkdir -p /var/www/html/pxe/netboots/ubuntu/24.04/x86_64/iso
        sudo mount /var/lib/bluebanquise/$ISO_NAME /var/www/html/pxe/netboots/ubuntu/24.04/x86_64/iso 2>/dev/null || true
        ;;
    debian13)
        sudo mkdir -p /var/www/html/pxe/netboots/debian/13/x86_64/iso
        sudo mount /var/lib/bluebanquise/$ISO_NAME /var/www/html/pxe/netboots/debian/13/x86_64/iso 2>/dev/null || true
        ;;
esac
export PYTHONPATH=\$PYTHONPATH
sudo bluebanquise-bootset -n $VM_NAME -b osdeploy
# Compatibility symlink for older iPXE clients.
sudo mkdir -p /var/www/html/preboot_execution_environment/
sudo ln -sf ../pxe/convergence.ipxe /var/www/html/preboot_execution_environment/convergence.ipxe
EOF

    # Destroy any leftover VM.
    virsh destroy "$VM_NAME" 2>/dev/null && log "  Destroyed existing $VM_NAME." || true
    virsh undefine "$VM_NAME" $UNDEFINE_FLAGS 2>/dev/null && log "  Undefined existing $VM_NAME." || true
    sudo rm -f /var/lib/libvirt/images/"$VM_NAME".qcow2

    # Create the VM with two NICs; it will PXE-boot from virbr1 (first NIC).
    log "  Creating $VM_NAME (PXE boot) ..."
    virt-install \
        --name="$VM_NAME" \
        --os-variant="$OS_VARIANT" \
        --ram=8192 \
        --vcpus=4 \
        --noreboot \
        --disk path=/var/lib/libvirt/images/"$VM_NAME".qcow2,bus=virtio,size=30 \
        --network bridge=virbr1,mac="$MAC_VIRBR1" \
        --network bridge=virbr2,mac="$MAC_VIRBR2" \
        --pxe \
        $BOOT_FLAGS

    # Reduce RAM for runtime.
    virsh setmem "$VM_NAME" 4G --config
    virsh start "$VM_NAME"

    log "  Waiting for $VM_NAME to come up at $MGMT_IP ..."
    sleep 30
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$MGMT_IP" 2>/dev/null || true

    # Wait via mgt1 (mgt1 can reach the mgmt VM on virbr1).
    $SSH_MGT1 "/tmp/waitforssh.sh $INITIAL_USER@$MGMT_IP"

    log "  $VM_NAME is up."
    STEP=10
fi
