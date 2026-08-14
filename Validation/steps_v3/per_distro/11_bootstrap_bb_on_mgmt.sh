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
    $SSH_MGT1 "/usr/local/bin/waitforssh.sh $INITIAL_USER@$MGMT_IP"

    # Download and run bootstrap (skip environment, we control the branch).
    log "  Running online_bootstrap.sh --skip_environment ..."
    $SSH_MGT1 "ssh $SSH_OPTS $INITIAL_USER@$MGMT_IP 'wget -q https://raw.githubusercontent.com/bluebanquise/bluebanquise/master/bootstrap/online_bootstrap.sh && chmod +x online_bootstrap.sh && sudo ./online_bootstrap.sh --silent --skip_environment'"

    # Copy host public key so the host can reach the mgmt VM as bluebanquise directly.
    # online_bootstrap.sh (even with --skip_environment) never creates
    # ~bluebanquise/.ssh — that only happens later in configure_environment.sh,
    # whose own authorized_keys logic expects the file to already exist by
    # then (it appends its own key rather than overwriting). Create the
    # directory ourselves first (same gap as 04_deploy_bb_on_mgt1.sh's mgt1 path).
    HOST_PUBKEY=$(cat "$HOME/.ssh/id_ed25519.pub")
    $SSH_MGT1 "ssh $SSH_OPTS $INITIAL_USER@$MGMT_IP '\
        sudo mkdir -p /var/lib/bluebanquise/.ssh && \
        sudo chown bluebanquise:bluebanquise /var/lib/bluebanquise/.ssh && \
        sudo chmod 700 /var/lib/bluebanquise/.ssh && \
        cat .ssh/authorized_keys | sudo tee /var/lib/bluebanquise/.ssh/authorized_keys && \
        sudo chown bluebanquise:bluebanquise /var/lib/bluebanquise/.ssh/authorized_keys && \
        sudo chmod 600 /var/lib/bluebanquise/.ssh/authorized_keys'"
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

    # Add waitforssh helper to mgmt VM. Installed under /usr/local/bin (not
    # /tmp) so it survives this VM's own nic-role self-reboot in per_distro/12
    # (ubuntu24/debian13 hit that reboot too, same as mgt1 does in step 04) —
    # see 03_bootstrap_mgt1.sh for the same fix and why /tmp isn't safe here.
    $SCP_MGMT "$CURRENT_DIR/../functions/waitforssh.sh" bluebanquise@"$MGMT_IP":/tmp/waitforssh.sh
    $SSH_MGMT "sudo install -m 755 /tmp/waitforssh.sh /usr/local/bin/waitforssh.sh"

    # Upload cluster inventory (clean copy each time). Uploaded as
    # "cluster_inventory", not "cluster" — BlueBanquise's own cluster_management/
    # pxe_stack roles reserve /var/lib/bluebanquise/cluster/ as their runtime
    # state directory (cluster/hosts/<hostname>/... per their README), and a
    # plain-named "cluster" upload here collides directly: the inventory's own
    # "hosts" file lands at the exact path pxe_stack expects to create as a
    # directory, so it fails with "already exists as a file" the first time
    # any cluster-node-state task runs (2026-08-09 live failure).
    log "  Uploading cluster inventory for $distro ..."
    $SCP_MGMT -r "$INVENTORY_DIR" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/cluster_inventory
    $SCP_MGMT -r "$CURRENT_DIR/../playbooks" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/

    # Inject mgmt VM's bluebanquise pubkey as os_admin_ssh_keys (for PXE-installed cluster nodes).
    MGMT_PUBKEY=$($SSH_MGMT 'cat /var/lib/bluebanquise/.ssh/id_ed25519.pub')
    $SSH_MGMT "echo 'os_admin_ssh_keys=[\"$MGMT_PUBKEY\"]' >> /var/lib/bluebanquise/cluster_inventory/hosts"

    # Inject munge key into slurm.yml.
    $SSH_MGMT "echo 'slurm_munge_key_b64: \"$SLURM_MUNGE_KEY_B64\"' >> /var/lib/bluebanquise/cluster_inventory/group_vars/all/slurm.yml"

    # Add 127.0.0.1 mgt so Ansible can connect to the management node itself.
    $SSH_MGMT "echo '127.0.0.1 mgt' | sudo tee -a /etc/hosts"
    $SSH_MGMT "ssh $SSH_OPTS mgt hostname"

    log "  BB bootstrap on $distro mgmt VM complete."
    STEP=11
fi
