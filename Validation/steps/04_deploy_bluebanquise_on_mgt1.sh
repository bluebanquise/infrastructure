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

    remote_pubkey=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip /bin/echo \$\(cat /var/lib/bluebanquise/.ssh/id_ed25519.pub\))
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF

cd validation/inventories/
mkdir -p minimal/group_vars/all/
cp bb_core.yml minimal/group_vars/all/
echo ep_admin_ssh_keys=[\"$remote_pubkey\"] >> minimal/hosts
echo 127.0.0.1 mgt1 | sudo tee -a /etc/hosts
ssh -o StrictHostKeyChecking=no mgt1 hostname

EOF

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
cd validation/inventories/ 
ansible-playbook ../playbooks/managements.yml -i minimal --limit mgt1 -b
EOF

fi

if (( $STEP < 7 )); then
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $CURRENT_DIR/../http/AlmaLinux-8-latest-x86_64-dvd.iso bluebanquise@$mgt1_ip:/var/lib/bluebanquise/AlmaLinux-8-latest-x86_64-dvd.iso

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bluebanquise@$mgt1_ip <<EOF
sudo mkdir -p /var/www/html/pxe/netboots/redhat/8/x86_64/iso
sudo mount /var/lib/bluebanquise/AlmaLinux-8-latest-x86_64-dvd.iso /var/www/html/pxe/netboots/redhat/8/x86_64/iso
/bin/bash -c 'sudo bluebanquise-bootset -n c001 -b osdeploy'
# temporary fix
sudo mkdir -p /var/www/html/preboot_execution_environment/
cd /var/www/html/preboot_execution_environment/
sudo ln -s ../pxe/convergence.ipxe convergence.ipxe
EOF

fi
