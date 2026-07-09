#!/usr/bin/env bash
# Deploy the permanent Ubuntu 24.04 mgt1 VM via cloud-init autoinstall.
# mgt1 has two NICs: virbr0 (internet/host access) and virbr1 (cluster bootstrap).
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( STEP < 3 )); then
    log "03 Bootstrap mgt1 (Ubuntu 24.04)."

    # Download Ubuntu 24.04 ISO if not cached.
    cd "$CURRENT_DIR/../http"
    ISO=ubuntu-24.04-live-server-amd64.iso
    if [ ! -f "$ISO" ]; then
        log "  Downloading $ISO ..."
        wget -nc https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
    fi

    # Extract kernel and initrd for direct kernel boot.
    sudo mkdir -p /bbmnt
    ! mountpoint -q /bbmnt || sudo umount /bbmnt
    sudo mount "$ISO" /bbmnt
    cp -a /bbmnt/casper/initrd . && chmod 666 initrd
    cp -a /bbmnt/casper/vmlinuz . && chmod 666 vmlinuz
    sudo umount /bbmnt

    # Inject host SSH key into cloud-init user-data.
    rm -f "$CURRENT_DIR/../http/user-data"
    cp "$CURRENT_DIR/../http/user-data.template" "$CURRENT_DIR/../http/user-data"
    echo "          - $(cat "$HOME/.ssh/id_ed25519.pub")" >> "$CURRENT_DIR/../http/user-data"

    sudo mkdir -p /data/images
    sudo chown -R "$USER":"$USER" /data/images

    # Destroy any existing mgt1.
    virsh destroy mgt1 2>/dev/null && log "  mgt1 destroyed." || true
    virsh undefine mgt1 2>/dev/null && log "  mgt1 undefined." || true

    log "  Installing mgt1 via PXE/cloud-init ..."
    virt-install \
        --os-variant ubuntu24.04 \
        --name=mgt1 \
        --ram=8192 \
        --vcpus=4 \
        --check mac_in_use=off \
        --noreboot \
        --disk path=/data/images/mgt1.qcow2,bus=virtio,size=24 \
        --network bridge=virbr0,mac="$MGT1_MAC_VIRBR0" \
        --network bridge=virbr1,mac=52:54:00:fa:12:02 \
        --install kernel=http://$HOST_IP:$HOST_HTTP_PORT/vmlinuz,initrd=http://$HOST_IP:$HOST_HTTP_PORT/initrd,kernel_args_overwrite=yes,kernel_args="root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://$HOST_IP:$HOST_HTTP_PORT/$ISO autoinstall ds=nocloud-net;s=http://$HOST_IP:$HOST_HTTP_PORT/"

    # Reduce RAM for runtime (installation needs 8 GB).
    virsh setmem mgt1 4G --config

    log "  Starting mgt1 ..."
    virsh start mgt1
    sleep 30

    export MGT1_IP=$(virsh net-dhcp-leases default | grep "$MGT1_MAC_VIRBR0" | tail -1 | awk '{print $5}' | sed 's|/.*||')
    log "  mgt1 IP: $MGT1_IP"

    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$MGT1_IP" 2>/dev/null || true

    log "  Waiting for mgt1 SSH ..."
    "$CURRENT_DIR/functions/waitforssh.sh" "generic@$MGT1_IP"

    log "  Initial setup on mgt1 ..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@"$MGT1_IP" \
        "sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"

    # Configure mgt1 as gateway for virbr1 (10.10.0.0/16).
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@"$MGT1_IP" << 'EOF'
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o enp1s0 -j MASQUERADE
EOF

    # Expand LVM to use full disk.
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@"$MGT1_IP" << 'EOF'
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
EOF

    # Copy waitforssh helper onto mgt1 for later use.
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$CURRENT_DIR/functions/waitforssh.sh" generic@"$MGT1_IP":/tmp/waitforssh.sh

    log "  mgt1 ready."
    STEP=3
fi
