#!/bin/bash

if (( $STEP < 3 )); then
    echo " 03 Bootstrap mgt1."
    echo "  - Deploying base OS..."

    virt-install --name=vmgt1 --ram=8192 --vcpus=14 --noreboot --disk path=/data/images/mgt1.qcow2,bus=virtio,size=60 --network bridge=virbr0,mac=52:54:00:fa:12:01 --network bridge=virbr1,mac=52:54:00:fa:12:02 --install kernel=http://$host_ip:8000/kernels/mgt1/vmlinuz,initrd=http://$host_ip:8000/kernels/mgt1/initrd,kernel_args_overwrite=yes,kernel_args="root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://$host_ip:8000/isos/ubuntu-20.04.2-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://$host_ip:8000/autoinstall/mgt1/"

    echo "  - Stopping host http server."
    ./kill_http_server.sh

fi

if (( $STEP < 4 )); then

    echo "  - Starting VM and wait 5s."
    virsh start vmgt1

    echo "  - Getting mgt1 ip."
    sleep 10
    export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | awk -F ' ' '{print $5}' | sed 's/\/24//')
    echo "  $mgt1_ip"

    echo "Waiting for VM to be ready at $mgt1_ip"
    set +e
    $CURRENT_DIR/functions/waitforssh.sh bluebanquise@$mgt1_ip
    set -e
    echo "  - Estabilishing link with mgt1."

   # sshpass -e ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip sudo apt-get update

    echo "  - Configuring mgt1 as gateway."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip << EOF
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o ens2 -j MASQUERADE
EOF

    echo "  - Expand default FS."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip << EOF
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
EOF

fi

echo "  - Getting mgt1 ip."
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | awk -F ' ' '{print $5}' | sed 's/\/24//')
echo "  $mgt1_ip"