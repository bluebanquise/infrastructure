#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')
# Prepare target deployment
mgt1_PYTHONPATH=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip pip3 show ClusterShell | grep Location | awk -F ' ' '{print $2}')

cd $CURRENT_DIR/../http
wget -nc https://mirror.its.dal.ca/opensuse/distribution/leap/15.4/iso/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso
cd $CURRENT_DIR

ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo mkdir -p /var/www/html/pxe/netboots/sles/15/x86_64/iso
sudo mount /var/lib/bluebanquise/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso /var/www/html/pxe/netboots/sles/15/x86_64/iso
export PYTHONPATH=$mgt1_PYTHONPATH
sudo bluebanquise-bootset -n mgt7 -b osdeploy
# temporary fix
sudo mkdir -p /var/www/html/preboot_execution_environment/
cd /var/www/html/preboot_execution_environment/
sudo rm -f convergence.ipxe
sudo ln -s ../pxe/convergence.ipxe convergence.ipxe
EOF

virsh destroy mgt7
virsh undefine mgt7
virt-install --name=mgt7 --os-variant sle15 --ram=6000 --vcpus=4 --noreboot --disk path=/var/lib/libvirt/images/mgt7.qcow2,bus=virtio,size=10 --network bridge=virbr1,mac=1a:2b:3c:4d:7e:8f --pxe
virsh start mgt7
sleep 60

# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
ssh-keygen -f "/var/lib/bluebanquise/.ssh/known_hosts" -R mgt7
ssh -o StrictHostKeyChecking=no mgt7 hostname
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt7 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying Ubuntu 22.04 mgt7
else
  echo FAILED deploying Ubuntu 22.04 mgt7
  exit 1
fi

# Cleaning
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo umount /var/www/html/pxe/netboots/sles/15/x86_64/iso
sudo rm /var/lib/bluebanquise/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso
ssh -o StrictHostKeyChecking=no mgt7 sudo shutdown -h now
EOF
