#!/usr/bin/env bash
# Tear down all VMs for the current distro run:
#   - Destroy and undefine login1, c001, c002, and mgmt_<distro>
#   - Unmount ISO on mgt1 and remove it
#   - Reset bluebanquise-bootset to default for the mgmt VM entry on mgt1

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

VM_NAME=${DISTRO_VM_NAME[$distro]}
ISO_NAME=${DISTRO_ISO_NAME[$distro]}
UNDEFINE_FLAGS=${DISTRO_UNDEFINE_FLAGS[$distro]}

log "17 [$distro] Cleanup."

# Destroy cluster nodes.
for node in c002 c001 login1; do
    virsh destroy "$node" 2>/dev/null && log "  $node destroyed." || true
    virsh undefine "$node" $UNDEFINE_FLAGS 2>/dev/null && log "  $node undefined." || true
    sudo rm -f /var/lib/libvirt/images/"$node".qcow2
done

# Destroy the mgmt VM.
virsh destroy "$VM_NAME" 2>/dev/null && log "  $VM_NAME destroyed." || true
virsh undefine "$VM_NAME" $UNDEFINE_FLAGS 2>/dev/null && log "  $VM_NAME undefined." || true
sudo rm -f /var/lib/libvirt/images/"$VM_NAME".qcow2

# Remove the netboot from mgt1 via the official tool, then remove our own
# uploaded ISO copy manually (the tool's own copy, made during `install`
# inside the managed netboot tree, is already gone once uninstall runs — this
# is the *separate* staging copy per_distro/10 uploaded to /var/lib/bluebanquise/).
# Only mgt1 needs this: the mgmt VM's own netboot install (for login1/c001/
# c002) disappears for free when its whole disk image is deleted above.
NETBOOT_ID=${DISTRO_NETBOOT_ID[$distro]}
$SSH_MGT1 << EOF || true
set +e
PYTHONPATH=\$(pip3 show ClusterShell 2>/dev/null | grep Location | awk '{print \$2}')
export PYTHONPATH=\$PYTHONPATH
# Defensive: a netboot set up by the old raw-mount approach (pre-2026-08-11)
# leaves an active loop mount under the netboot tree's iso/ subdir, which
# would make the tool's own rmtree fail with "Device or resource busy".
# Harmless no-op once every distro has gone through the new tool-based
# install path (nothing will ever be mounted there again).
case "$distro" in
    rhel9)   sudo umount /var/www/html/pxe/netboots/redhat/9/x86_64/iso 2>/dev/null || true ;;
    rhel10)  sudo umount /var/www/html/pxe/netboots/redhat/10/x86_64/iso 2>/dev/null || true ;;
    ubuntu24) sudo umount /var/www/html/pxe/netboots/ubuntu/24.04/x86_64/iso 2>/dev/null || true ;;
    debian13) sudo umount /var/www/html/pxe/netboots/debian/13/x86_64/iso 2>/dev/null || true ;;
esac
sudo bluebanquise-netboots-installer uninstall $NETBOOT_ID $DISTRO_NETBOOT_ARCH -q
rm -f /var/lib/bluebanquise/$ISO_NAME
EOF

# Reset the mgmt VM's PXE boot mode to default on mgt1.
$SSH_MGT1 << EOF || true
PYTHONPATH=\$(pip3 show ClusterShell 2>/dev/null | grep Location | awk '{print \$2}')
export PYTHONPATH=\$PYTHONPATH
sudo bluebanquise-bootset -n $VM_NAME -b default
EOF

log "  [$distro] Cleanup complete."

# Reset per-distro step counter for the next distro.
STEP=9
