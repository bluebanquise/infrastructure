#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')
# Prepare target deployment
mgt1_PYTHONPATH=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip pip3 show ClusterShell | grep Location | awk -F ' ' '{print $2}')

cd $CURRENT_DIR/../http
wget -nc https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso
cd $CURRENT_DIR

ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/ubuntu-22.04.1-live-server-amd64.iso

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo mkdir -p /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/iso
sudo mv /var/lib/bluebanquise/ubuntu-22.04.1-live-server-amd64.iso /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/
sudo mount /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/ubuntu-22.04.1-live-server-amd64.iso /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/iso
sudo ln -s ./ubuntu-22.04.1-live-server-amd64.iso /var/lib/bluebanquise/ubuntu-22.04-live-server-amd64.iso
export PYTHONPATH=$mgt1_PYTHONPATH
sudo bluebanquise-bootset -n mgt6 -b osdeploy
# temporary fix
sudo mkdir -p /var/www/html/preboot_execution_environment/
cd /var/www/html/preboot_execution_environment/
sudo rm -f convergence.ipxe
sudo ln -s ../pxe/convergence.ipxe convergence.ipxe
EOF

virsh destroy mgt6
virsh undefine mgt6
virt-install --name=mgt6 --os-variant ubuntu22.04 --ram=6000 --vcpus=4 --noreboot --disk path=/var/lib/libvirt/images/mgt6.qcow2,bus=virtio,size=10 --network bridge=virbr1,mac=1a:2b:3c:4d:6e:8f --pxe
virsh start mgt6
sleep 60

# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
ssh-keygen -f "/var/lib/bluebanquise/.ssh/known_hosts" -R mgt6
ssh -o StrictHostKeyChecking=no mgt6 hostname
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt6 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying Ubuntu 22.04 mgt6
else
  echo FAILED deploying Ubuntu 22.04 mgt6
  exit 1
fi

# Cleaning
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo umount /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/iso
sudo rm /var/www/html/pxe/netboots/ubuntu/22.04/x86_64/ubuntu-22.04.1-live-server-amd64.iso
sudo shutdown -h now
EOF
