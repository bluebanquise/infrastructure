#!/usr/bin/env bash
# Run logins.yml and computes.yml from the mgmt VM, on freshly PXE-deployed
# login1, c001 and c002 (no manual OS preparation: repositories come from the
# inventory, through the repositories role).

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

ANSIBLE_ENV="source /var/lib/bluebanquise/ansible_venv/bin/activate && export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg && cd /var/lib/bluebanquise"

if (( STEP < 15 )); then
    log "15 [$distro] Deploy stacks on login1, c001, c002."

    # ansible-playbook checks host keys strictly: seed the nodes' ones.
    for node in login1 c001 c002; do
        $SSH_MGMT "ssh-keygen -f ~/.ssh/known_hosts -R $node 2>/dev/null; \
                   ssh -o StrictHostKeyChecking=accept-new bluebanquise@$node true"
    done

    log "  Running logins.yml --limit login1 ..."
    $SSH_MGMT "$ANSIBLE_ENV && ansible-playbook playbooks/logins.yml -i cluster_inventory --limit login1 -b"
    log "  login1 deployment: SUCCESS"

    log "  Running computes.yml --limit c001,c002 ..."
    $SSH_MGMT "$ANSIBLE_ENV && ansible-playbook playbooks/computes.yml -i cluster_inventory --limit c001,c002 -b"
    log "  c001/c002 deployment: SUCCESS"

    STEP=15
fi
