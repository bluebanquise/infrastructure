#!/usr/bin/env bash
# Bootstrap BlueBanquise on mgt1 and deploy the full management stack
# so mgt1 can PXE-deploy the per-distro cluster management VMs.
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( STEP < 4 )); then
    log "04 Deploy BlueBanquise on mgt1."

    export MGT1_IP=$(virsh net-dhcp-leases default | grep "$MGT1_MAC_VIRBR0" | tail -1 | awk '{print $5}' | sed 's|/.*||')
    log "  mgt1 IP: $MGT1_IP"

    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    # Install BB: create user + deps (skip environment to control branch).
    log "  Running online_bootstrap.sh --skip_environment ..."
    ssh $SSH_OPTS generic@"$MGT1_IP" << EOF
wget -q https://raw.githubusercontent.com/bluebanquise/bluebanquise/master/bootstrap/online_bootstrap.sh
chmod +x online_bootstrap.sh
sudo ./online_bootstrap.sh --silent --skip_environment
EOF

    # Copy host SSH key so the host can later reach mgt1 as bluebanquise.
    ssh $SSH_OPTS generic@"$MGT1_IP" \
        "cat .ssh/authorized_keys | sudo tee -a /var/lib/bluebanquise/.ssh/authorized_keys"

    # Clone the desired branch and install the collection.
    log "  Cloning BlueBanquise branch: $BB_BRANCH ..."
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << EOF
set -e
cd /var/lib/bluebanquise
git clone -b $BB_BRANCH https://github.com/bluebanquise/bluebanquise.git
cd bluebanquise/bootstrap/
./configure_environment.sh --bb_collections_local_path=/var/lib/bluebanquise/bluebanquise/collections/infrastructure
EOF

    # Upload the mgt1 bootstrap inventory and playbooks.
    log "  Uploading mgt1 bootstrap inventory and playbooks ..."
    scp $SSH_OPTS -r \
        "$CURRENT_DIR/inventories/mgt1_bootstrap" \
        bluebanquise@"$MGT1_IP":/var/lib/bluebanquise/

    scp $SSH_OPTS -r \
        "$CURRENT_DIR/playbooks" \
        bluebanquise@"$MGT1_IP":/var/lib/bluebanquise/

    # Inject mgt1's bluebanquise pubkey as os_admin_ssh_keys in the inventory.
    MGT1_PUBKEY=$(ssh $SSH_OPTS bluebanquise@"$MGT1_IP" 'cat /var/lib/bluebanquise/.ssh/id_ed25519.pub')
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "echo 'os_admin_ssh_keys=[\"$MGT1_PUBKEY\"]' >> /var/lib/bluebanquise/mgt1_bootstrap/hosts"

    # Add 127.0.0.1 mgt1 so Ansible can SSH to itself.
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "echo '127.0.0.1 mgt1' | sudo tee -a /etc/hosts"

    # Add BlueBanquise apt repo so pxe_stack can install its packages.
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << 'EOF'
sudo curl -s https://bluebanquise.com/repository/releases/latest/u24/x86_64/bluebanquise/bluebanquise.list \
    --output /etc/apt/sources.list.d/bluebanquise.list
sudo apt-get update -q
EOF

    # Run the management playbook on mgt1.
    log "  Running managements_full.yml on mgt1 ..."
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << 'EOF'
set -e
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/managements_full.yml \
    -i mgt1_bootstrap --limit mgt1 -b
EOF

    if [ $? -eq 0 ]; then
        log "  mgt1 BB deployment: SUCCESS"
    else
        log "  mgt1 BB deployment: FAILED"
        exit 1
    fi

    STEP=4
fi
