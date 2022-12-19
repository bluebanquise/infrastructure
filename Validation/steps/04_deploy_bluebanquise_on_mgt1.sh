#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( $STEP < 5 )); then

    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $CURRENT_DIR/validation bluebanquise@$mgt1_ip:/home/bluebanquise/

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip bash <<EOF

git clone https://github.com/bluebanquise/bluebanquise.git
cd bluebanquise
cp -a ../validation resources/examples/validation

sed -i bootstrap_input.sh '/SAMPLE_INVENTORY/d'
sed -i bootstrap_input.sh '/UBUNTU_2004_ISO_URL/d'
sed -i bootstrap_input.sh '/UBUNTU_2004_ISO/d'
sed -i bootstrap_input.sh '/REDHAT_8_ISO_URL/d'
sed -i bootstrap_input.sh '/REDHAT_8_ISO/d'

echo "SAMPLE_INVENTORY=validation" >> bootstrap_input.sh
echo "UBUNTU_2004_ISO_URL=http://192.168.122.1:8000/isos/ubuntu-20.04.4-live-server-amd64.iso" >> bootstrap_input.sh
echo "UBUNTU_2004_ISO=ubuntu-20.04.4-live-server-amd64.iso" >> bootstrap_input.sh
echo "REDHAT_8_ISO_URL=http://192.168.122.1:8000/isos/AlmaLinux-8.5-x86_64-dvd.iso" >> bootstrap_input.sh
echo "REDHAT_8_ISO=AlmaLinux-8.5-x86_64-dvd.iso" >> bootstrap_input.sh

./bootstrap.sh

EOF

fi
if (( $STEP < 6 )); then

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF

export ANSIBLE_CONFIG=/home/bluebanquise/bluebanquise/ansible.cfg
cd bluebanquise/playbooks
ansible-playbook managements.yml --limit mgt1 -b
sudo bootset -n c[001-004],mg[2-4] -b osdeploy

EOF

fi