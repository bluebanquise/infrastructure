#!/usr/bin/env bash
# Run the full management stack playbook on the per-distro mgmt VM.
# This configures: repositories, set_hostname, http_server, nic, hosts_file,
# dhcp_server, dns_server, clustershell, pxe_stack, time (server), firewall,
# nfs (server), slurm (controller), users.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

if (( STEP < 12 )); then
    log "12 [$distro] Deploy full management stack on mgmt VM."

    # ansible-playbook's default (strict) host_key_checking rejects even a
    # completely fresh self-connection on a VM with empty known_hosts —
    # non-interactive SSH can't prompt, so unknown-host and changed-host both
    # fail identically as "Host key verification failed". Seed it before the
    # nic-only pass below can need it (see 04_deploy_bb_on_mgt1.sh for the
    # same fix on mgt1, found the hard way there first).
    log "  Seeding mgt VM's self-loopback host key in known_hosts ..."
    $SSH_MGMT \
        "ssh-keygen -f ~/.ssh/known_hosts -R mgt 2>/dev/null; \
         ssh-keygen -f ~/.ssh/known_hosts -R 127.0.0.1 2>/dev/null; \
         ssh -o StrictHostKeyChecking=accept-new mgt true"

    # On Ubuntu/Debian, the nic role reboots to switch netplan to
    # NetworkManager. The mgmt VM is both controller and target here (it
    # reaches itself via the "127.0.0.1 mgt" alias from step 11), so the
    # reboot kills the whole VM — ansible-playbook included — not just the
    # inner Ansible-to-target connection the reboot module knows how to ride
    # out. Run nic alone first and tolerate the outer SSH connection dropping
    # (expected, not a failure; a no-op on RHEL where nic never reboots), wait
    # for the VM back up, then run the full stack (nic is then idempotent).
    log "  Running nic role alone first (VM may reboot itself, connection drop expected) ..."
    set +e
    $SSH_MGMT << 'EOF'
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/managements_full.yml -i cluster_inventory --limit mgt -b --tags nic
EOF
    set -e

    log "  Waiting for mgt VM to be reachable ..."
    sleep 15
    MGMT_IP=${DISTRO_MGMT_VIRBR1_IP[$distro]}
    $SSH_MGT1 "/usr/local/bin/waitforssh.sh bluebanquise@$MGMT_IP"

    # Same known_hosts refresh as mgt1 (see 04_deploy_bb_on_mgt1.sh): the
    # reboot presents a host key ansible-playbook's default-strict checking
    # hasn't validated, since the nic-only pass's self-connection above only
    # ever did a first-contact accept, not a match check. No-op on RHEL (no
    # reboot happened, but re-seeding an already-trusted key is harmless).
    $SSH_MGMT \
        "ssh-keygen -f ~/.ssh/known_hosts -R mgt 2>/dev/null; \
         ssh-keygen -f ~/.ssh/known_hosts -R 127.0.0.1 2>/dev/null; \
         ssh -o StrictHostKeyChecking=accept-new mgt true"

    $SSH_MGMT << 'EOF'
set -e
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/managements_full.yml -i cluster_inventory --limit mgt -b
EOF

    if [ $? -eq 0 ]; then
        log "  Management stack deployment: SUCCESS"
    else
        log "  Management stack deployment: FAILED"
        exit 1
    fi

    # Re-enable gateway masquerade after nic role may have reset networking.
    $SSH_MGMT << 'EOF'
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -C POSTROUTING -s 10.20.0.0/16 -o enp1s0 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -o enp1s0 -j MASQUERADE
EOF

    # Ensure NFS export directories exist before clients mount.
    $SSH_MGMT << 'EOF'
sudo mkdir -p /home /opt/software
sudo mkdir -p /home/testuser
sudo chown 1500:1500 /home/testuser
EOF

    log "  Management stack ready."
    STEP=12
fi
