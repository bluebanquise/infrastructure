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

    $SSH_MGMT << 'EOF'
set -e
source /var/lib/bluebanquise/ansible_venv/bin/activate
export ANSIBLE_CONFIG=/var/lib/bluebanquise/bluebanquise/ansible.cfg
cd /var/lib/bluebanquise
ansible-playbook playbooks/managements_full.yml -i cluster --limit mgt -b
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
