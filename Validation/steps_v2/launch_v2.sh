echo
LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#sudo apt-get update && sudo apt-get install -y qemu-kvm virt-manager libvirt-daemon-system virtinst libvirt-clients bridge-utils
#sudo systemctl enable libvirtd
#sudo systemctl start libvirtd
#sudo usermod -aG kvm $USER
#sudo usermod -aG libvirt $USER
#newgrp kvm
#newgrp libvirt
#trap "kill -9 $(ps -ax | grep 'http.server 8000' | sed 2d | awk -F ' ' '{print $1}')" EXIT


echo "Starting test."
set -e
source values.sh

#####################################################################################################
########## PREPARE CORE
#########################

# CONFIGURE Virtual NETWORK
if (( $STEP < 1 )); then
    set -x
    echo " Setup networks."
    echo "  - Creating VMs private network."
    set +e
    virsh net-list --all | grep private_network
    if [ $? -ne 0 ]; then
        set -e
        virsh net-define $CURRENT_DIR/vms/private_network.xml
    virsh net-start private_network
    fi
    set -e
fi

if (( $STEP < 2 )); then

    echo " 02 Start http server."
    echo "   - Grabing isos"
    mkdir -p $CURRENT_DIR/http
    cd $CURRENT_DIR/http
    wget -nc https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso
    #wget -nc https://releases.ubuntu.com/20.04/ubuntu-20.04.5-live-server-amd64.iso
    echo "   - Extracting boot files"
    sudo mkdir -p /bbmnt
    ! mountpoint -q /bbmnt || sudo umount /bbmnt
    sudo mount ubuntu-24.04.4-live-server-amd64.iso /bbmnt
    cp -a /bbmnt/casper/initrd . && chmod 666 initrd
    cp -a /bbmnt/casper/vmlinuz . && chmod 666 vmlinuz
    (
    set -x
    cd $CURRENT_DIR/http
    ps -ax | grep 'python3 -m http.server 8000'
#    if [ $? -eq 1 ]; then
       python3 -m http.server 8000 > http_server.log 2>&1
#    fi
    ) &
    export http_server_pid=$!
    echo "  - http server pid: $http_server_pid"
fi

if (( $STEP < 3 )); then
    echo " 03 Bootstrap mgt1."

    # Inject host ssh key into user-data
    rm -f $CURRENT_DIR/http/user-data
    rm -f $CURRENT_DIR/http/meta-data
    cp $CURRENT_DIR/user-data.template $CURRENT_DIR/http/user-data
    cp $CURRENT_DIR/meta-data $CURRENT_DIR/http/meta-data
    echo "          - $(cat $HOME/.ssh/id_ed25519.pub)" >> $CURRENT_DIR/http/user-data

    sudo mkdir -p /data/images
    CUSER=$USER
    sudo chown -R $CUSER:$CUSER /data/images 
    echo "  - Deploying base OS..."

    virsh destroy mgt1 && echo "mgt1 destroyed" || echo "mgt1 not found, skipping"
    virsh undefine mgt1 && echo "mgt1 undefined" || echo "mgt1 not found, skipping"

    virt-install --os-variant ubuntu24.04 --name=mgt1 --ram=12000 --vcpus=4 --check mac_in_use=off --noreboot --disk path=/data/images/mgt1_2.qcow2,bus=virtio,size=24 --network bridge=virbr0,mac=52:54:00:fa:12:01 --network bridge=virbr1,mac=52:54:00:fa:12:02 --install kernel=http://$host_ip:8000/vmlinuz,initrd=http://$host_ip:8000/initrd,kernel_args_overwrite=yes,kernel_args="root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://$host_ip:8000/ubuntu-24.04.4-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://$host_ip:8000/"

    # Reduce memory once installed, no need for more
    virsh setmem mgt1 2G --config

fi

if (( $STEP < 4 )); then

    echo "  - Starting VM and wait 30s."
    virsh start mgt1

    echo "  - Getting mgt1 ip."
    sleep 30
    export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')
    echo "  $mgt1_ip"

    ssh-keygen -f "$HOME/.ssh/known_hosts" -R $mgt1_ip

    echo "Waiting for VM to be ready at $mgt1_ip"
    set +e
    $CURRENT_DIR/functions/waitforssh.sh generic@$mgt1_ip
    set -e
    echo "  - Estabilishing link with mgt1."

   # sshpass -e ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip sudo apt-get update
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y

    echo "  - Configuring mgt1 as gateway."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip << EOF
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o enp1s0 -j MASQUERADE
EOF

    echo "  - Expand default FS."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip << EOF
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
EOF

    echo "  - Send waitssh."
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $CURRENT_DIR/functions/waitforssh.sh generic@$mgt1_ip:/tmp/waitforssh.sh

fi


#####################################################################################################
########## DEPLOY DEBIAN 13 CLUSTER
#########################


exit

cd $LAUNCH_CURRENT_DIR
if (( $STEP < 3 )); then
    source steps/03_bootstrap_mgt1.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 9 )); then
    source steps/04_deploy_bluebanquise_on_mgt1.sh
fi
# cd $LAUNCH_CURRENT_DIR
# if (( $STEP < 20 )); then
#     source steps/06_deploy_rhel8.sh
# fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 20 )); then
    source steps/07_deploy_rhel9.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 30 )); then
    source steps/06_deploy_rhel10.sh
fi
cd $LAUNCH_CURRENT_DIR
#if (( $STEP < 40 )); then
#    source steps/08_deploy_rhel7.sh
#fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 50 )); then
    source steps/09_deploy_ubuntu20.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 60 )); then
    source steps/10_deploy_ubuntu22.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 70 )); then
    source steps/11_deploy_osl13.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 80 )); then
    # Note: if this part fails when grabing repos, clean netboot and kernels everywhere, and relaunch
    source steps/12_deploy_debian11.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 90 )); then
    source steps/13_deploy_debian12.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 100 )); then
    source steps/14_deploy_ubuntu24.sh
fi

