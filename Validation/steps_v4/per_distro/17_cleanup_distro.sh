#!/usr/bin/env bash
# Remove all VMs of the distro run, and their disks. Only reached when the
# whole distro run passed: a failure stops launch_v4.sh with the VMs left in
# place for inspection.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"

if (( STEP < 17 )); then
    log "17 [$distro] Cleanup."

    for vm in c002 c001 login1 "$(mgmt_vm_name "$distro")"; do
        destroy_vm "$vm"
        rm -f "$IMAGES_DIR/$vm-serial.log"
    done

    log "  [$distro] Cleanup complete."
fi
