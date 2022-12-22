#!/bin/bash
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( $STEP < 5 )); then

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip wget https://raw.githubusercontent.com/bluebanquise/bluebanquise/dev/2.0/bootstrap/online_bootstrap.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip chmod +x online_bootstrap.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip ./online_bootstrap.sh silent

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null generic@$mgt1_ip 'sudo cat .ssh/authorized_keys >> /var/lib/bluebanquise/.ssh/authorized_keys'

    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $CURRENT_DIR/validation bluebanquise@$mgt1_ip:/var/lib/bluebanquise/


fi
if (( $STEP < 6 )); then

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF

#export ANSIBLE_CONFIG=/home/bluebanquise/bluebanquise/ansible.cfg
#cd bluebanquise/playbooks
set -x
cd validation/inventories/
mkdir -p minimal/group_vars/all/
cp bb_core.yml minimal/group_vars/all/
ansible-playbook ../playbooks/managements.yml -i minimal --limit mgt1 -b
#sudo bootset -n c[001-004],mg[2-4] -b osdeploy

EOF

fi
