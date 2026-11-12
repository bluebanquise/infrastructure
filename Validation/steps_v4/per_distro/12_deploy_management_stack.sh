#!/usr/bin/env bash
# Run the full management stack playbook on the mgmt VM: repositories,
# local_configuration, http_server, nic, firewall (with the gateway policy of
# host_vars/mgt), hosts_file, dhcp_server, dns_server, clustershell,
# pxe_stack, time (server), nfs (server), slurm (controller), users.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

ANSIBLE_ENV="source /var/lib/bluebanquise/ansible_venv/bin/activate && export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg && cd /var/lib/bluebanquise"

# ansible-playbook checks host keys strictly: (re)seed the mgmt VM's own one.
seed_self_host_key() {
    $SSH_MGMT "ssh-keygen -f ~/.ssh/known_hosts -R mgt 2>/dev/null; \
               ssh-keygen -f ~/.ssh/known_hosts -R 127.0.0.1 2>/dev/null; \
               ssh -o StrictHostKeyChecking=accept-new mgt true"
}

if (( STEP < 12 )); then
    log "12 [$distro] Deploy full management stack on mgmt VM."

    seed_self_host_key

    # On some distributions the nic role reboots to switch to NetworkManager.
    # The mgmt VM is both controller and target here, so the reboot kills
    # ansible-playbook itself: run nic alone first, tolerate the connection
    # drop, wait for the VM, then run the full stack (nic is then idempotent).
    log "  Running nic role alone first (VM may reboot itself, connection drop expected) ..."
    set +e
    $SSH_MGMT "$ANSIBLE_ENV && ansible-playbook playbooks/managements_full.yml -i cluster_inventory --limit mgt -b --tags nic"
    set -e

    sleep 15
    timeout 600 "$CURRENT_DIR/../functions/waitforssh.sh" "bluebanquise@$MGMT_IP"
    seed_self_host_key

    log "  Running managements_full.yml ..."
    $SSH_MGMT "$ANSIBLE_ENV && ansible-playbook playbooks/managements_full.yml -i cluster_inventory --limit mgt -b"
    log "  Management stack deployment: SUCCESS"

    # testuser's home on the NFS export, before clients mount it.
    $SSH_MGMT "sudo mkdir -p /home/testuser /opt/software && sudo chown 1500:1500 /home/testuser"

    STEP=12
fi
