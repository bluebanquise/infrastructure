#!/bin/bash

if (( $STEP < 3 )); then
    echo " 03 Bootstrap mgt1."
    sudo mkdir -p /data/images
    CUSER=$USER
    sudo chown -R $CUSER:$CUSER /data/images 
    echo "  - Deploying base OS..."

    virt-install --os-variant ubuntu22.04 --name=vmgt1 --ram=8192 --vcpus=4 --noreboot --disk path=/data/images/mgt1.qcow2,bus=virtio,size=24 --network bridge=virbr0,mac=52:54:00:fa:12:01 --network bridge=virbr1,mac=52:54:00:fa:12:02 --install kernel=http://$host_ip:8000/vmlinuz,initrd=http://$host_ip:8000/initrd,kernel_args_overwrite=yes,kernel_args="root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://$host_ip:8000/ubuntu-22.04.1-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://$host_ip:8000/"
#virt-install --os-variant ubuntu20.04 --name=vmgt1 --ram=8192 --vcpus=4 --noreboot --disk path=/data/images/mgt1.qcow2,bus=virtio,size=24 --network bridge=virbr0,mac=52:54:00:fa:12:01 --install kernel=http://$host_ip:8000/vmlinuz,initrd=http://$host_ip:8000/initrd,kernel_args_overwrite=yes,kernel_args="root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://$host_ip:8000/ubuntu-20.04.5-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://$host_ip:8000/"

#    echo "  - Stopping host http server."
#    ./kill_http_server.sh

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
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y

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

echo "  - Getting mgt1 ip if was skipped before."
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | awk -F ' ' '{print $5}' | sed 's/\/24//')
echo "  $mgt1_ip"
