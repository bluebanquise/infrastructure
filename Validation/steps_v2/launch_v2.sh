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


export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')

if (( $STEP < 6 )); then

  # Bootstrap BlueBanquise
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip wget https://raw.githubusercontent.com/bluebanquise/bluebanquise/master/bootstrap/online_bootstrap.sh
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip chmod +x online_bootstrap.sh
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip ./online_bootstrap.sh --silent
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip 'cat .ssh/authorized_keys | sudo tee -a /var/lib/bluebanquise/.ssh/authorized_keys'

  # From now, we work as bluebanquise sudo user
  ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip hostname
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $CURRENT_DIR/validation bluebanquise@$mgt1_ip:/var/lib/bluebanquise/
fi

if (( $STEP < 7 )); then

    remote_pubkey=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip /bin/echo \$\(cat /var/lib/bluebanquise/.ssh/id_ed25519.pub\))
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
set -x
cd validation/inventories/
echo os_admin_ssh_keys=[\"$remote_pubkey\"] >> hosts_root_mgmt
echo 127.0.0.1 mgt1 | sudo tee -a /etc/hosts
ssh -o StrictHostKeyChecking=no mgt1 hostname
EOF

# #OS_ADMIN_SSH_KEYS

# [os_dynamic]
# c001
# c002
# # Add here the needed os parameters per cycle


ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo curl http://bluebanquise.com/repository/releases/latest/u24/x86_64/bluebanquise/bluebanquise.list --output /etc/apt/sources.list.d/bluebanquise.list
sudo apt update
EOF
fi

if (( $STEP < 8 )); then
# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
source /var/lib/bluebanquise/ansible_venv/bin/activate
cd validation/ 
export ANSIBLE_JINJA2_EXTENSIONS=jinja2.ext.loopcontrols,jinja2.ext.do
ansible-playbook playbooks/managements.yml -i inventories --limit mgt1 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying mgt1
else
  echo FAILED deploying mgt1
  exit 1
fi

fi


#####################################################################################################
########## DEPLOY EL 10 CLUSTER
#########################


if (( $STEP < 20 )); then

cd $CURRENT_DIR/http
wget -nc https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.2-x86_64-dvd1.iso
cd $CURRENT_DIR

ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/Rocky-10.2-x86_64-dvd1.iso

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
set -x
sudo mkdir -p /var/www/html/pxe/netboots/redhat/10/x86_64/iso
sudo mount /var/lib/bluebanquise/Rocky-10.2-x86_64-dvd1.iso /var/www/html/pxe/netboots/redhat/10/x86_64/iso
export PYTHONPATH=$mgt1_PYTHONPATH
sudo bluebanquise-bootset -n mgt2 -b osdeploy
EOF

virsh destroy mgt2 && echo "mgt2 destroyed" || echo "mgt2 not found, skipping"
virsh undefine mgt2 && echo "mgt2 undefined" || echo "mgt2 not found, skipping"
virt-install --name=mgt2 --os-variant rhel8-unknown --ram=10000 --vcpus=4 --noreboot --disk path=/var/lib/libvirt/images/mgt2.qcow2,bus=virtio,size=10 --network bridge=virbr1,52:54:00:fa:00:02 --pxe
virsh setmem mgt2 2G --config
virsh start mgt2
fi

if (( $STEP < 21 )); then

# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J bluebanquise@$mgt1_ip <<EOF
ssh-keygen -f "/var/lib/bluebanquise/.ssh/known_hosts" -R mgt2
/tmp/waitforssh.sh bluebanquise@mgt2
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
ssh -o StrictHostKeyChecking=no mgt2 hostname
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
ssh -o StrictHostKeyChecking=no mgt2 sudo curl http://bluebanquise.com/repository/releases/latest/el10/x86_64/bluebanquise/bluebanquise.repo --output /etc/yum.repos.d/bluebanquise.repo
EOF
set +e
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
set -x
#sleep 200 # wait for network to stabilize
ssh -o StrictHostKeyChecking=no mgt2 'sudo dnf install wget -y && wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm && sudo dnf install epel-release-latest-10.noarch.rpm -y && sudo dnf update -y && sudo reboot -h now
'
EOF
set -e
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
/tmp/waitforssh.sh bluebanquise@mgt2
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF

scp -o StrictHostKeyChecking=no mgt2 -r /var/lib/bluebanquise/validation mgt2:/var/lib/bluebanquise/
ssh -o StrictHostKeyChecking=no mgt2 <<EOOF
wget https://raw.githubusercontent.com/bluebanquise/bluebanquise/master/bootstrap/configure_environment.sh
chmod +x configure_environment.sh
configure_environment.sh
EOOF
ssh -o StrictHostKeyChecking=no mgt2 <<EOOF
source /var/lib/bluebanquise/ansible_venv/bin/activate
cd validation/ 
sed -i 's/"services_ip":"10.10.0.1"/"services_ip":"10.10.0.2"/' hosts_root_mgmt
ssh_public_key=$(cat /var/lib/bluebanquise/.ssh/id_ed25519.pub)

cat <<EOOOF >> hosts_too_mgmt
os_admin_ssh_keys=[\"$(cat $HOME/.ssh/id_ed25519.pub)\"]

[os_rhel10:vars]
os_operating_system={'distribution':"redhat", 'distribution_version':"10", 'distribution_major_version':"10" }



export ANSIBLE_JINJA2_EXTENSIONS=jinja2.ext.loopcontrols,jinja2.ext.do
ansible-playbook playbooks/managements.yml -i inventories --limit mgt2 -b
EOOF



source /var/lib/bluebanquise/ansible_venv/bin/activate
cd validation/inventories/
export ANSIBLE_VARS_ENABLED=ansible.builtin.host_group_vars,bluebanquise.commons.core
export ANSIBLE_JINJA2_EXTENSIONS=jinja2.ext.loopcontrols,jinja2.ext.do
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt2 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying RHEL 8 on mgt2
else
  echo FAILED deploying RHEL 8 on mgt2
  exit 1
fi

# Cleaning
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo umount /var/www/html/pxe/netboots/redhat/10/x86_64/iso
rm Rocky-10.2-x86_64-dvd1.iso
EOF
virsh shutdown mgt2

fi





















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

