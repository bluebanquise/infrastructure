#!/usr/bin/env bash
# Install the cluster's management VM straight from the distribution ISO, with
# the distribution's own unattended file: what an admin does with a USB key on
# the first server of a cluster. Two NICs: uplink on the $UPLINK_NETWORK NAT
# network (internet), cluster NIC on $CLUSTER_NETWORK (left unconfigured, the
# BlueBanquise nic role configures it later).

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"

VM_NAME=$(mgmt_vm_name "$distro")
FAMILY=${DISTRO_FAMILY[$distro]}
ISO_PATH=$ISO_DIR/${DISTRO_ISO_NAME[$distro]}
MAC_UPLINK=${DISTRO_MGMT_MAC_UPLINK[$distro]}
MAC_CLUSTER=${DISTRO_MGMT_MAC_CLUSTER[$distro]}
DISTRO_UNATTENDED_DIR=$UNATTENDED_DIR/$distro

# Replace the @...@ placeholders of an unattended template.
render_unattended() {
    local template=$1
    local target=$2
    sed -e "s|@HOSTNAME@|$MGMT_HOSTNAME|g" \
        -e "s|@USER@|$INSTALL_USER|g" \
        -e "s|@PASSWORD_HASH@|$PASSWORD_HASH|g" \
        -e "s|@SSH_KEY@|$SSH_KEY|g" \
        -e "s|@MAC_UPLINK@|$MAC_UPLINK|g" \
        -e "s|@UPLINK_INTERFACE@|enp1s0|g" \
        "$CURRENT_DIR/../unattended/$template" > "$target"
}

if (( STEP < 10 )); then
    log "10 [$distro] Install $VM_NAME from ISO (the USB key install)."

    # Downloaded once, through a .part file so a cut download is never taken
    # for a complete ISO. Retried: wget gives up at once on a DNS failure.
    # Rate capped: the hypervisor overheats on sustained fast downloads.
    if [ ! -f "$ISO_PATH" ]; then
        log "  Downloading ${DISTRO_ISO_NAME[$distro]} ..."
        DOWNLOADED=false
        for i in $(seq 1 30); do
            wget -nv -c --limit-rate=1900k -O "$ISO_PATH.part" "${DISTRO_ISO_URL[$distro]}" && DOWNLOADED=true && break
            sleep 20
        done
        if ! $DOWNLOADED; then
            log "  Download failed 30 times."
            exit 1
        fi
        mv "$ISO_PATH.part" "$ISO_PATH"
    fi

    log "  Rendering unattended files in $DISTRO_UNATTENDED_DIR ..."
    rm -rf "$DISTRO_UNATTENDED_DIR"
    mkdir -p "$DISTRO_UNATTENDED_DIR"
    PASSWORD_HASH=$(openssl passwd -6 "$INSTALL_USER_PASSWORD")
    SSH_KEY=$(cat "$HOME/.ssh/id_ed25519.pub")

    # Console on the serial port too, logged to a file next to the disk, so an
    # unattended install can be followed (and debugged) without a display.
    CONSOLE_ARGS="console=tty0 console=ttyS0,115200n8"
    # virt-install finds the installer kernel by itself on RHEL and Debian
    # media, not on live ISOs (Ubuntu live-server, Leap Agama): paths given.
    LOCATION="$ISO_PATH"
    case "$FAMILY" in
        redhat)
            render_unattended redhat.ks "$DISTRO_UNATTENDED_DIR/ks.cfg"
            INSTALL_ARGS=(--initrd-inject "$DISTRO_UNATTENDED_DIR/ks.cfg"
                          --extra-args "inst.ks=file:/ks.cfg inst.text $CONSOLE_ARGS")
            ;;
        debian)
            render_unattended debian.preseed "$DISTRO_UNATTENDED_DIR/preseed.cfg"
            INSTALL_ARGS=(--initrd-inject "$DISTRO_UNATTENDED_DIR/preseed.cfg"
                          --extra-args "priority=critical $CONSOLE_ARGS")
            ;;
        ubuntu)
            # Autoinstall config on a second CD-ROM labelled CIDATA (cloud-init
            # NoCloud seed, found without network: like the USB key, no
            # server needed, and the host firewall blocks VMs anyway).
            render_unattended ubuntu.user-data "$DISTRO_UNATTENDED_DIR/user-data"
            touch "$DISTRO_UNATTENDED_DIR/meta-data"
            xorriso -as genisoimage -quiet -output "$DISTRO_UNATTENDED_DIR/seed.iso" -volid CIDATA \
                -joliet -rock "$DISTRO_UNATTENDED_DIR/user-data" "$DISTRO_UNATTENDED_DIR/meta-data"
            LOCATION="$ISO_PATH,kernel=casper/vmlinuz,initrd=casper/initrd"
            INSTALL_ARGS=(--disk path="$DISTRO_UNATTENDED_DIR/seed.iso",device=cdrom
                          --extra-args "autoinstall $CONSOLE_ARGS")
            ;;
        suse)
            # Agama profile on a second CD-ROM, found by its label (same
            # reason as the Ubuntu seed).
            render_unattended suse.agama.json "$DISTRO_UNATTENDED_DIR/profile.json"
            xorriso -as genisoimage -quiet -output "$DISTRO_UNATTENDED_DIR/agama.iso" -volid AGAMA \
                -joliet -rock "$DISTRO_UNATTENDED_DIR/profile.json"
            LOCATION="$ISO_PATH,kernel=boot/x86_64/loader/linux,initrd=boot/x86_64/loader/initrd"
            INSTALL_ARGS=(--disk path="$DISTRO_UNATTENDED_DIR/agama.iso",device=cdrom
                          --extra-args "inst.auto=label://AGAMA/profile.json inst.finish=poweroff $CONSOLE_ARGS")
            ;;
    esac

    destroy_vm "$VM_NAME"
    rm -f "$IMAGES_DIR/$VM_NAME-serial.log"

    # 12000M is for the installation only, dropped to 4000M before the first
    # boot on disk. The unattended files all end with a power off.
    # --wait 0: virt-install returns at once, so that the uplink bandwidth cap
    # is set before the installer starts downloading.
    log "  Installing $VM_NAME (serial console log: $IMAGES_DIR/$VM_NAME-serial.log) ..."
    virt-install \
        --name "$VM_NAME" \
        --os-variant "${DISTRO_OS_VARIANT[$distro]}" \
        --ram 12000 \
        --vcpus 4 \
        --disk path="$IMAGES_DIR/$VM_NAME.qcow2",size=80,bus=virtio,format=qcow2 \
        --network network="$UPLINK_NETWORK",mac="$MAC_UPLINK",model=virtio \
        --network network="$CLUSTER_NETWORK",mac="$MAC_CLUSTER",model=virtio \
        --location "$LOCATION" \
        "${INSTALL_ARGS[@]}" \
        --serial pty,log.file="$IMAGES_DIR/$VM_NAME-serial.log" \
        --graphics vnc,listen=127.0.0.1 \
        $(firmware_flags "$distro") \
        --noautoconsole \
        --noreboot \
        --wait 0

    # All the cluster's internet traffic goes through this uplink (the nodes
    # use the mgmt VM as gateway): capped, the hypervisor's network link
    # overheats on sustained load.
    virsh domiftune "$VM_NAME" "$MAC_UPLINK" --inbound "$UPLINK_RATE_KBPS" --outbound "$UPLINK_RATE_KBPS" --live --config

    for i in $(seq 1 240); do
        [ "$(virsh domstate "$VM_NAME")" == "shut off" ] && break
        sleep 30
    done
    if [ "$(virsh domstate "$VM_NAME")" != "shut off" ]; then
        log "  $VM_NAME installation did not finish in 2 hours (state: $(virsh domstate "$VM_NAME"))."
        log "  Look at: virsh screenshot $VM_NAME /tmp/$VM_NAME.png, and the serial log."
        exit 1
    fi

    virsh setmem "$VM_NAME" 4000M --config
    virsh start "$VM_NAME"

    setup_ssh_aliases "$distro"
    log "  Waiting for SSH on $INSTALL_USER@$MGMT_IP ..."
    timeout 600 "$CURRENT_DIR/../functions/waitforssh.sh" "$INSTALL_USER@$MGMT_IP"

    log "  $VM_NAME is up at $MGMT_IP, hostname: $($SSH_INSTALL uname -n)."
    STEP=10
fi
