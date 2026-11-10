#!/usr/bin/env bash
# On the mgmt VM, install the netboot of its own distribution from the ISO,
# and set login1, c001 and c002 to OS deployment.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

VM_NAME=$(mgmt_vm_name "$distro")
ISO_NAME=${DISTRO_ISO_NAME[$distro]}
NETBOOT_ID=${DISTRO_NETBOOT_ID[$distro]}

if (( STEP < 13 )); then
    log "13 [$distro] Prepare PXE on mgmt VM for cluster nodes."

    # The ISO is plugged into the VM as a read-only disk (the admin inserts
    # the DVD) and copied locally: a network copy would go through the
    # uplink bandwidth cap.
    log "  Plugging $ISO_NAME into the mgmt VM and copying it ..."
    # Found in the VM by its serial (the guest names the disk itself, vdb...).
    virsh attach-disk "$VM_NAME" "$ISO_DIR/$ISO_NAME" vdz --mode readonly --serial validationiso --live
    $SSH_MGMT "for i in \$(seq 1 30); do [ -b /dev/disk/by-id/virtio-validationiso ] && break; sleep 1; done; \
               sudo dd if=/dev/disk/by-id/virtio-validationiso of=/var/lib/bluebanquise/$ISO_NAME bs=4M status=none && \
               sudo chown bluebanquise: /var/lib/bluebanquise/$ISO_NAME"
    virsh detach-disk "$VM_NAME" vdz --live

    # --netboot installs from the local ISO (airgapped path) instead of
    # downloading it again. The ISO copy is removed once installed.
    log "  Installing netboot ($NETBOOT_ID) and running bootset ..."
    $SSH_MGMT "sudo bluebanquise-netboots-installer install $NETBOOT_ID $DISTRO_NETBOOT_ARCH --netboot /var/lib/bluebanquise/$ISO_NAME -q"
    $SSH_MGMT "rm -f /var/lib/bluebanquise/$ISO_NAME"
    for node in login1 c001 c002; do
        $SSH_MGMT "sudo bluebanquise-bootset -n $node -b osdeploy"
    done

    log "  PXE ready for login1, c001, c002."
    STEP=13
fi
