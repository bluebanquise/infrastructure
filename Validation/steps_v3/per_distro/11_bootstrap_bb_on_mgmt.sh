#!/usr/bin/env bash
# Bootstrap BlueBanquise on the per-distro mgmt VM:
#   - OS pre-setup (EPEL on RHEL, package updates)
#   - online_bootstrap.sh --skip_environment (creates bluebanquise user + deps)
#   - Manual git clone of the chosen branch + configure_environment.sh
#   - Gateway configuration (ip_forward + iptables masquerade for virbr2)
#   - Upload cluster inventory with injected pubkey and munge key

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

MGMT_IP=${DISTRO_MGMT_VIRBR1_IP[$distro]}
INITIAL_USER=${DISTRO_INITIAL_USER[$distro]}
PRE_BOOTSTRAP=${DISTRO_PRE_BOOTSTRAP[$distro]}
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
INVENTORY_DIR="$CURRENT_DIR/../inventories/cluster/$distro"

if (( STEP < 11 )); then
    log "11 [$distro] Bootstrap BlueBanquise on $MGMT_IP."

    # OS pre-setup (EPEL + updates) — may reboot on RHEL.
    log "  OS pre-setup ..."
    $SSH_MGT1 "ssh $SSH_OPTS $INITIAL_USER@$MGMT_IP '$PRE_BOOTSTRAP'" || true

    # If the pre-setup rebooted the VM, wait for it to come back.
    sleep 10
    $SSH_MGT1 "/tmp/waitforssh.sh $INITIAL_USER@$MGMT_IP"

    # Download and run bootstrap (skip environment, we control the branch).
    log "  Running online_bootstrap.sh --skip_environment ..."
    $SSH_MGT1 "ssh $SSH_OPTS $INITIAL_USER@$MGMT_IP 'wget -q https://raw.githubusercontent.com/bluebanquise/bluebanquise/master/bootstrap/online_bootstrap.sh && chmod +x online_bootstrap.sh && sudo ./online_bootstrap.sh --silent --skip_environment'"

    # Copy host public key so the host can reach the mgmt VM as bluebanquise directly.
    HOST_PUBKEY=$(cat "$HOME/.ssh/id_ed25519.pub")
    $SSH_MGT1 "ssh $SSH_OPTS $INITIAL_USER@$MGMT_IP 'cat .ssh/authorized_keys | sudo tee /var/lib/bluebanquise/.ssh/authorized_keys'"
    $SSH_MGT1 "ssh $SSH_OPTS bluebanquise@$MGMT_IP \"echo '$HOST_PUBKEY' >> /var/lib/bluebanquise/.ssh/authorized_keys\""

    # Clone the desired branch and install the collection as bluebanquise.
    log "  Installing BlueBanquise branch $BB_BRANCH on mgmt VM ..."
    $SSH_MGT1 << EOF
ssh $SSH_OPTS bluebanquise@$MGMT_IP << 'INNEREOF'
set -e
cd /var/lib/bluebanquise
git clone -b $BB_BRANCH https://github.com/bluebanquise/bluebanquise.git
cd bluebanquise/bootstrap/
./configure_environment.sh --bb_collections_local_path=/var/lib/bluebanquise/bluebanquise/collections/infrastructure
INNEREOF
EOF

    # Configure mgmt VM as gateway for virbr2 (10.20.0.0/16 → enp1s0 → mgt1).
    log "  Configuring mgmt VM as gateway for virbr2 ..."
    $SSH_MGMT << 'EOF'
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -o enp1s0 -j MASQUERADE
EOF

    # Add waitforssh helper to mgmt VM.
    $SCP_MGMT "$CURRENT_DIR/../functions/waitforssh.sh" bluebanquise@"$MGMT_IP":/tmp/waitforssh.sh

    # Upload cluster inventory (clean copy each time).
    log "  Uploading cluster inventory for $distro ..."
    $SCP_MGMT -r "$INVENTORY_DIR" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/cluster
    $SCP_MGMT -r "$CURRENT_DIR/../playbooks" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/

    # Inject mgmt VM's bluebanquise pubkey as os_admin_ssh_keys (for PXE-installed cluster nodes).
    MGMT_PUBKEY=$($SSH_MGMT 'cat /var/lib/bluebanquise/.ssh/id_ed25519.pub')
    $SSH_MGMT "echo 'os_admin_ssh_keys=[\"$MGMT_PUBKEY\"]' >> /var/lib/bluebanquise/cluster/hosts"

    # Inject munge key into slurm.yml.
    $SSH_MGMT "echo 'slurm_munge_key_b64: \"$SLURM_MUNGE_KEY_B64\"' >> /var/lib/bluebanquise/cluster/group_vars/all/slurm.yml"

    # Add 127.0.0.1 mgt so Ansible can connect to the management node itself.
    $SSH_MGMT "echo '127.0.0.1 mgt' | sudo tee -a /etc/hosts"
    $SSH_MGMT "ssh $SSH_OPTS mgt hostname"

    log "  BB bootstrap on $distro mgmt VM complete."
    STEP=11
fi
