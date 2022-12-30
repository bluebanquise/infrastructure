#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../http
wget -nc https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso
cd $CURRENT_DIR

if (( $STEP < 7 )); then
ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/AlmaLinux-9-latest-x86_64-dvd.iso

# Prepare target deployment
mgt1_PYTHONPATH=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip pip3 show ClusterShell | grep Location | awk -F ' ' '{print $2}')

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo mkdir -p /var/www/html/pxe/netboots/redhat/9/x86_64/iso
sudo mount /var/lib/bluebanquise/AlmaLinux-9-latest-x86_64-dvd.iso /var/www/html/pxe/netboots/redhat/9/x86_64/iso
export PYTHONPATH=$mgt1_PYTHONPATH
sudo bluebanquise-bootset -n mgt3 -b osdeploy
# temporary fix
sudo mkdir -p /var/www/html/preboot_execution_environment/
cd /var/www/html/preboot_execution_environment/
sudo rm -f convergence.ipxe
sudo ln -s ../pxe/convergence.ipxe convergence.ipxe
EOF

fi

if (( $STEP < 8 )); then
    virsh destroy mgt3
    virsh undefine mgt3
    virt-install --name=mgt3 --os-variant rhel8-unknown --ram=6000 --vcpus=4 --noreboot --disk path=/var/lib/libvirt/images/mgt3.qcow2,bus=virtio,size=10 --network bridge=virbr1,mac=1a:2b:3c:4d:3e:8f --pxe
fi

# Validation step
if (( $STEP < 9 )); then
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/ 
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt3 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying RHEL 9 mgt3
else
  echo FAILED deploying RHEL 9 mgt3
  exit 1
fi

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo umount /var/www/html/pxe/netboots/redhat/9/x86_64/iso
rm AlmaLinux-9-latest-x86_64-dvd.iso
EOF

fi