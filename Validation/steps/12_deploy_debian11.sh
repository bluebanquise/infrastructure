#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')
# Prepare target deployment
mgt1_PYTHONPATH=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip pip3 show ClusterShell | grep Location | awk -F ' ' '{print $2}')

cd $CURRENT_DIR/../http
wget --no-parent -r -l 0 --cut-dirs 5 -nH -A iso https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/
export DEBIAN_ISO=$(ls debian*.iso)
wget -nc https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/netboot.tar.gz
cd $CURRENT_DIR

ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/netboot.tar.gz
ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip wget -nc http://$host_ip:8000/$DEBIAN_ISO

# Debian preparation is extensive, we need to inject ata/scsi modules into netboot initrd
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo mkdir -p /var/www/html/pxe/netboots/debian/11/x86_64/
sudo mount $DEBIAN_ISO /mnt
rm -Rf /tmp/netboot
mkdir -p /tmp/netboot/iso
mkdir /tmp/netboot/netboot
cp /mnt/install.amd/initrd.gz /tmp/netboot/iso/
tar xvzf netboot.tar.gz
cp netboot/debian-installer/amd64/initrd.gz /tmp/netboot/netboot/
cd /tmp/netboot/iso/
gunzip initrd.gz
mkdir tmp2 && cd tmp2

sudo mount /var/lib/bluebanquise/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso /var/www/html/pxe/netboots/sles/15/x86_64/iso
export PYTHONPATH=$mgt1_PYTHONPATH
sudo bluebanquise-bootset -n mgt8 -b osdeploy
# temporary fix
sudo mkdir -p /var/www/html/preboot_execution_environment/
cd /var/www/html/preboot_execution_environment/
sudo rm -f convergence.ipxe
sudo ln -s ../pxe/convergence.ipxe convergence.ipxe
EOF

virsh destroy mgt8
virsh undefine mgt8
virt-install --name=mgt8 --os-variant debian11 --ram=6000 --vcpus=4 --noreboot --disk path=/var/lib/libvirt/images/mgt8.qcow2,bus=virtio,size=10 --network bridge=virbr1,mac=1a:2b:3c:4d:7e:8f --pxe
virsh start mgt8
sleep 60

# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
ssh-keygen -f "/var/lib/bluebanquise/.ssh/known_hosts" -R mgt8
ssh -o StrictHostKeyChecking=no mgt8 hostname
EOF
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt8 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying Ubuntu 22.04 mgt8
else
  echo FAILED deploying Ubuntu 22.04 mgt8
  exit 1
fi

# Cleaning
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo umount /var/www/html/pxe/netboots/sles/15/x86_64/iso
sudo rm /var/lib/bluebanquise/openSUSE-Leap-15.4-DVD-x86_64-Build243.2-Media.iso
EOF
virsh shutdown mgt8
