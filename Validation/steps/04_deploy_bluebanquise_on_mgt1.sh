#!/bin/bash

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip bash <<EOF

git clone https://github.com/bluebanquise/bluebanquise.git
cd bluebanquise

sed -i bootstrap_input.sh '/SAMPLE_INVENTORY/d'
sed -i bootstrap_input.sh '/UBUNTU_2004_ISO_URL/d'
sed -i bootstrap_input.sh '/UBUNTU_2004_ISO/d'
sed -i bootstrap_input.sh '/REDHAT_8_ISO_URL/d'
sed -i bootstrap_input.sh '/REDHAT_8_ISO/d'

echo "SAMPLE_INVENTORY=coconutshaker" >> bootstrap_input.sh
echo "UBUNTU_2004_ISO_URL=http://192.168.122.1:8000/isos/ubuntu-20.04.4-live-server-amd64.iso" >> bootstrap_input.sh
echo "UBUNTU_2004_ISO=ubuntu-20.04.4-live-server-amd64.iso" >> bootstrap_input.sh
echo "REDHAT_8_ISO_URL=http://192.168.122.1:8000/isos/AlmaLinux-8.5-x86_64-dvd.iso" >> bootstrap_input.sh
echo "REDHAT_8_ISO=AlmaLinux-8.5-x86_64-dvd.iso" >> bootstrap_input.sh

./bootstrap.sh

EOF

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip bash <<EOF

cd playbooks
ansible-playbook managements.yml --limit mgt1
sudo bootset -n c[001-004],mg[2-4] -b osdeploy

EOF
