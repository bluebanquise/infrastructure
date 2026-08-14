#!/usr/bin/env bash
# Run logins.yml and computes.yml from the per-distro mgmt VM.
# Ansible on the mgmt VM connects to login1/c001/c002 via the cluster network
# (10.20.0.0/16) using the bluebanquise SSH key.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

if (( STEP < 15 )); then
    log "15 [$distro] Deploy stacks on login1, c001, c002."

    # Update packages if needed and reboot RHEL nodes (EPEL + dnf update).
    case "$distro" in
        rhel9|rhel10)
            log "  Pre-setup on RHEL cluster nodes ..."
            for node in login1 c001 c002; do
                $SSH_MGMT << EOF || true
set -x
ssh $SSH_OPTS bluebanquise@$node 'sudo dnf install -y epel-release && sudo dnf update -y && sudo reboot -h now'
EOF
            done
            sleep 30
            for node in login1 c001 c002; do
                $SSH_MGMT "/usr/local/bin/waitforssh.sh bluebanquise@$node"
            done
            ;;
        ubuntu24|debian13)
            log "  Pre-setup on Debian-family cluster nodes ..."
            for node in login1 c001 c002; do
                $SSH_MGMT "ssh $SSH_OPTS bluebanquise@$node 'sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'" || true
            done
            ;;
    esac

    # ansible-playbook (unlike the ssh calls above, which pass
    # StrictHostKeyChecking=no + UserKnownHostsFile=/dev/null and so never
    # record anything) uses the bluebanquise user's real known_hosts with
    # default-strict checking — login1/c001/c002 have never had a real
    # first-contact connection recorded, so it fails "Host key verification
    # failed" on its very first attempt (same failure class as mgt1's and the
    # mgmt VM's own self-loopback, fixed elsewhere; this path was missed).
    # Seed all three before the first ansible-playbook run needs them.
    log "  Seeding login1/c001/c002 host keys in known_hosts ..."
    for node in login1 c001 c002; do
        $SSH_MGMT \
            "ssh-keygen -f ~/.ssh/known_hosts -R $node 2>/dev/null; \
             ssh -o StrictHostKeyChecking=accept-new bluebanquise@$node true"
    done

    # Deploy login node stack.
    log "  Running logins.yml --limit login1 ..."
    $SSH_MGMT << 'EOF'
set -e
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/logins.yml -i cluster_inventory --limit login1 -b
EOF

    if [ $? -eq 0 ]; then
        log "  login1 deployment: SUCCESS"
    else
        log "  login1 deployment: FAILED"
        exit 1
    fi

    # Deploy compute node stacks.
    log "  Running computes.yml --limit c001,c002 ..."
    $SSH_MGMT << 'EOF'
set -e
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/computes.yml -i cluster_inventory --limit c001,c002 -b
EOF

    if [ $? -eq 0 ]; then
        log "  c001/c002 deployment: SUCCESS"
    else
        log "  c001/c002 deployment: FAILED"
        exit 1
    fi

    log "  All node stacks deployed."
    STEP=15
fi
