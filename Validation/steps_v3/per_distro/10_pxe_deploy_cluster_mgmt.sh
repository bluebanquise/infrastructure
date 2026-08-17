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

    # Prefetch every other distro's ISO in the background so those downloads
    # overlap with this distro's cluster deployment (BB bootstrap, PXE nodes,
    # Slurm test, cleanup below) instead of each one only starting, serially,
    # once its own turn comes up in the per-distro loop. Skips anything
    # already cached or already being fetched by an earlier iteration.
    for prefetch_distro in "${DISTROS[@]}"; do
        [ "$prefetch_distro" == "$distro" ] && continue
        prefetch_iso=${DISTRO_ISO_NAME[$prefetch_distro]}
        prefetch_url=${DISTRO_ISO_URL[$prefetch_distro]}
        prefetch_path="$CURRENT_DIR/../../http/$prefetch_iso"
        if [ ! -f "$prefetch_path" ] && ! pgrep -f "wget.*$prefetch_iso" > /dev/null; then
            log "  Prefetching $prefetch_iso in background (for $prefetch_distro's later turn) ..."
            nohup wget -nc -P "$CURRENT_DIR/../../http/" "$prefetch_url" \
                > "$CURRENT_DIR/../../http/prefetch_${prefetch_distro}.log" 2>&1 &
            disown
        fi
    done

    # Transfer ISO to mgt1 (fetched from host HTTP server).
    log "  Transferring ISO to mgt1 ..."
    $SSH_MGT1 "wget -q -nc http://$HOST_IP:$HOST_HTTP_PORT/$ISO_NAME -P /var/lib/bluebanquise/"

    # RHEL/Rocky's dracut-based installer initrd waits for ALL detected NICs to reach a
    # terminal state before proceeding — including virbr2/net-cluster, which has no DHCP server
    # yet at install time (this VM is meant to provide that itself, later). Without pinning
    # activation to the admin NIC, nm-wait-online-initrd.service hangs indefinitely. Restrict it
    # via dedicated_kernel_parameters (wired through bootset -e, 2026-08-07) — Debian/Ubuntu use a
    # different network-config subsystem (netcfg/casper, not dracut) so this doesn't apply there.
    BOOTSET_EXTRA_ARGS=""
    case "$distro" in
        rhel9|rhel10)
            BOOTSET_EXTRA_ARGS="-e \"ifname=eth0:$MAC_VIRBR1 ip=eth0:dhcp\""
            ;;
    esac

    # Install the netboot via the official tool (airgapped: --netboot points
    # at the ISO already uploaded above, so it never touches the internet)
    # and run bluebanquise-bootset on mgt1 to set up PXE for this node.
    NETBOOT_ID=${DISTRO_NETBOOT_ID[$distro]}
    log "  Installing netboot ($NETBOOT_ID) and setting up PXE on mgt1 for $VM_NAME ..."
    $SSH_MGT1 << EOF
set -e
PYTHONPATH=\$(pip3 show ClusterShell 2>/dev/null | grep Location | awk '{print \$2}')
sudo bluebanquise-netboots-installer install $NETBOOT_ID $DISTRO_NETBOOT_ARCH --netboot /var/lib/bluebanquise/$ISO_NAME -q
export PYTHONPATH=\$PYTHONPATH
sudo bluebanquise-bootset -n $VM_NAME -b osdeploy $BOOTSET_EXTRA_ARGS
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
        --ram=12000 \
        --vcpus=4 \
        --noreboot \
        --disk path=/var/lib/libvirt/images/"$VM_NAME".qcow2,bus=virtio,size=30 \
        --network bridge=virbr1,mac="$MAC_VIRBR1" \
        --network bridge=virbr2,mac="$MAC_VIRBR2" \
        --pxe \
        $BOOT_FLAGS

    # 12000M was only needed for the install/provisioning boot (--ram above).
    # Drop to 4000M before the disk boot (2026-08-09, explicit request — 12000M
    # is provisioning-only, not a steady-state runtime requirement).
    virsh setmem "$VM_NAME" 4000M --config
    virsh start "$VM_NAME"

    log "  Waiting for $VM_NAME to come up at $MGMT_IP ..."
    sleep 30
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$MGMT_IP" 2>/dev/null || true

    # Wait via mgt1 (mgt1 can reach the mgmt VM on virbr1).
    $SSH_MGT1 "/usr/local/bin/waitforssh.sh $INITIAL_USER@$MGMT_IP"

    log "  $VM_NAME is up."
    STEP=10
fi
