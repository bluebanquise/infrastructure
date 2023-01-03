#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export mgt1_ip=$(virsh net-dhcp-leases default | grep '52:54:00:fa:12:01' | tail -1 | awk -F ' ' '{print $5}' | sed 's/\/24//')

if (( $STEP < 5 )); then

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip wget https://raw.githubusercontent.com/bluebanquise/bluebanquise/dev/2.0/bootstrap/online_bootstrap.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip chmod +x online_bootstrap.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip ./online_bootstrap.sh silent

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip 'cat .ssh/authorized_keys | sudo tee -a /var/lib/bluebanquise/.ssh/authorized_keys'

    ssh -o StrictHostKeyChecking=no bluebanquise@$mgt1_ip hostname
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $CURRENT_DIR/validation bluebanquise@$mgt1_ip:/var/lib/bluebanquise/


fi
if (( $STEP < 6 )); then

    remote_pubkey=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip /bin/echo \$\(cat /var/lib/bluebanquise/.ssh/id_ed25519.pub\))
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
set -x
cd validation/inventories/
mkdir -p minimal_extended/group_vars/all/
cp bb_core.yml minimal_extended/group_vars/all/
echo ep_admin_ssh_keys=[\"$remote_pubkey\"] >> minimal_extended/hosts
echo 127.0.0.1 mgt1 | sudo tee -a /etc/hosts
ssh -o StrictHostKeyChecking=no mgt1 hostname
EOF

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
echo 'deb [trusted=yes] http://bluebanquise.com/repository/releases/latest/ubuntu2004/x86_64/bluebanquise/ ./' | sudo tee /etc/apt/sources.list.d/bluebanquise.list
sudo apt update
EOF

# Validation step
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/ 
ansible-playbook ../playbooks/managements.yml -i minimal_extended --limit mgt1 -b
EOF
if [ $? -eq 0 ]; then
  echo SUCCESS deploying mgt1
else
  echo FAILED deploying mgt1
  exit 1
fi

fi

