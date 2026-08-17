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
    # online_bootstrap.sh (even with --skip_environment) never creates
    # ~bluebanquise/.ssh — that only happens later, in configure_environment.sh
    # below, whose own authorized_keys logic expects the file to already
    # contain this host key by then (it appends its own key rather than
    # overwriting). Create the directory ourselves first.
    ssh $SSH_OPTS generic@"$MGT1_IP" \
        "sudo mkdir -p /var/lib/bluebanquise/.ssh && \
         sudo chown bluebanquise:bluebanquise /var/lib/bluebanquise/.ssh && \
         sudo chmod 700 /var/lib/bluebanquise/.ssh && \
         cat .ssh/authorized_keys | sudo tee -a /var/lib/bluebanquise/.ssh/authorized_keys && \
         sudo chown bluebanquise:bluebanquise /var/lib/bluebanquise/.ssh/authorized_keys && \
         sudo chmod 600 /var/lib/bluebanquise/.ssh/authorized_keys"

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

    # Inject the shared munge key — the slurm role (profile: controller, part
    # of managements_full.yml) needs it regardless of slurm_enable_accounting;
    # without it, it falls back to a static munge.key file the role doesn't
    # ship, and fails. Same injection per_distro/11 already does for the
    # cluster inventories, just missing here for mgt1's own bootstrap run.
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "echo 'slurm_munge_key_b64=$SLURM_MUNGE_KEY_B64' >> /var/lib/bluebanquise/mgt1_bootstrap/hosts"

    # Add 127.0.0.1 mgt1 so Ansible can SSH to itself.
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "echo '127.0.0.1 mgt1' | sudo tee -a /etc/hosts"

    # Add BlueBanquise apt repo so pxe_stack can install its packages.
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << 'EOF'
sudo curl -s https://bluebanquise.com/repository/releases/latest/u24/x86_64/bluebanquise/bluebanquise.list \
    --output /etc/apt/sources.list.d/bluebanquise.list
sudo apt-get update -q
EOF

    # ansible-playbook (unlike our own ssh calls here) doesn't pass
    # StrictHostKeyChecking=no, and ansible.cfg's default host_key_checking is
    # strict — so on a completely fresh mgt1 (empty known_hosts), even this
    # FIRST-ever self-connection gets rejected: non-interactive SSH can't
    # prompt, so "unknown host" and "changed host" both produce the identical
    # "Host key verification failed", not just the changed-key case. Seed the
    # key before this first pass too, not only after the reboot below.
    log "  Seeding mgt1's self-loopback host key in known_hosts ..."
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "ssh-keygen -f ~/.ssh/known_hosts -R mgt1 2>/dev/null; \
         ssh-keygen -f ~/.ssh/known_hosts -R 127.0.0.1 2>/dev/null; \
         ssh -o StrictHostKeyChecking=accept-new mgt1 true"

    # The nic role reboots Ubuntu targets to switch netplan to NetworkManager
    # (nic_allow_reboot defaults true). mgt1 is both controller and target here
    # (Ansible reaches it via the "127.0.0.1 mgt1" alias added above), so the
    # reboot kills the whole mgt1 machine — ansible-playbook process included —
    # not just the inner Ansible-to-target SSH connection the reboot module
    # knows how to ride out. The outer SSH session below WILL be severed by
    # the reboot; that is expected, not a failure. Run nic alone first, tolerate
    # the drop, wait for mgt1 back up, then run the full stack (nic is then
    # idempotent — NetworkManager already active — so no second reboot fires).
    log "  Running nic role alone first (mgt1 will reboot itself, connection drop expected) ..."
    set +e
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << 'EOF'
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/managements_full.yml \
    -i mgt1_bootstrap --limit mgt1 -b --tags nic
EOF
    set -e

    log "  Waiting for mgt1 to reboot and come back up ..."
    sleep 15
    "$CURRENT_DIR/functions/waitforssh.sh" bluebanquise@"$MGT1_IP"

    # ansible-playbook (unlike our own ssh calls here) doesn't pass
    # StrictHostKeyChecking=no, so it relies on whatever's already trusted in
    # the bluebanquise user's own known_hosts on mgt1. The nic-only pass above
    # connected to the "mgt1" self-alias fine only because that was mgt1's
    # first-ever self-connection (new-key accept, not a match check); the
    # reboot presents a key that connection never validated against anything.
    # Clear any stale entry for both the alias and the 127.0.0.1 it resolves
    # to (SSH's CheckHostIP can cache either), then seed the current key with
    # one throwaway accept-new connection before ansible-playbook's own
    # (default-strict) connection needs it to already be trusted.
    log "  Refreshing mgt1's self-loopback host key in known_hosts ..."
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" \
        "ssh-keygen -f ~/.ssh/known_hosts -R mgt1 2>/dev/null; \
         ssh-keygen -f ~/.ssh/known_hosts -R 127.0.0.1 2>/dev/null; \
         ssh -o StrictHostKeyChecking=accept-new mgt1 true"

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

    # mgt1's own internet-gateway role (masquerading virbr1's 10.10.0.0/16 out
    # through enp1s0/virbr0) is a validation-harness artifact, not a typical
    # BlueBanquise deployment shape — a real management node doesn't usually
    # NAT its own uplink. The firewall role above already declares masquerade
    # on the 'internal' zone (mgt1_bootstrap inventory), which is real and
    # persistent — but masquerade alone doesn't cross firewalld's zone
    # boundary: enp1s0 was never assigned any zone by BlueBanquise (it isn't
    # declared in network_interfaces at all), so it sits in whatever default
    # zone NetworkManager gave it ('public'), and firewalld denies forwarding
    # from 'internal'-zone sources to a different egress zone without an
    # explicit policy object — something the firewall role has no support for
    # (checked 2026-08-09; only zone-level services/ports/rich-rules/masquerade
    # exist, no policy management). Kept here as a harness-only workaround
    # rather than extending the role, per explicit decision (Oxedions,
    # 2026-08-09) — this dual-NAT-hop topology only exists to simulate an
    # isolated network for validation. Idempotent: --new-policy is a no-op if
    # it already exists (rerunning 03+04 to rebuild mgt1 hits this every time).
    # --add-masquerade on the policy itself is required, not optional: the
    # zone-level 'masquerade':True declared via firewall_zones (mgt1_bootstrap
    # inventory) only NATs same-zone traffic. Cross-zone forwarded traffic
    # (exactly what this policy exists for) is a structurally different flow —
    # confirmed missing live (2026-08-11): forwarded packets left enp1s0 still
    # carrying their original 10.10.0.0/16 source (verified via tcpdump),
    # silently dropped upstream since a private source address never routes
    # over the real internet — no error anywhere, just 100% ping loss.
    log "  Allowing internal-zone traffic to forward out through mgt1's public-zone uplink ..."
    ssh $SSH_OPTS bluebanquise@"$MGT1_IP" << 'EOF' || true
sudo firewall-cmd --permanent --new-policy internal-to-public
sudo firewall-cmd --permanent --policy internal-to-public --add-ingress-zone internal
sudo firewall-cmd --permanent --policy internal-to-public --add-egress-zone public
sudo firewall-cmd --permanent --policy internal-to-public --set-target ACCEPT
sudo firewall-cmd --permanent --policy internal-to-public --add-masquerade
sudo firewall-cmd --reload
EOF

    STEP=4
fi
