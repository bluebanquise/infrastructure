#!/usr/bin/env bash
# Validate the Slurm cluster by running a job as testuser from login1.
# Waits for Slurm to be fully ready, then runs:
#   srun --nodes=2 --ntasks-per-node=1 hostname
# and verifies that both c001 and c002 appear in the output.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if (( STEP < 16 )); then
    log "16 [$distro] Slurm validation test."

    # Ensure testuser home exists on the NFS share (mgt owns the NFS export).
    $SSH_MGMT << 'EOF'
sudo mkdir -p /home/testuser
sudo chown 1500:1500 /home/testuser
sudo chmod 755 /home/testuser
EOF

    # Wait for Slurm to be ready: sinfo should show all compute nodes as idle.
    log "  Waiting for Slurm cluster to become ready ..."
    $SSH_MGMT << 'MGMTEOF'
source /var/lib/bluebanquise/ansible_venv/bin/activate
MAX_WAIT=300
ELAPSED=0
while true; do
    READY=$(sinfo --noheader -o "%T" 2>/dev/null | grep -c "idle" || true)
    if [ "$READY" -ge 2 ]; then
        echo "  Slurm: $READY nodes idle, cluster ready."
        break
    fi
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo "  Slurm not ready after ${MAX_WAIT}s. Dumping sinfo:"
        sinfo || true
        exit 1
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
    echo "  Waiting for Slurm nodes... ($ELAPSED s)"
done
MGMTEOF

    # Run the actual test from login1 as testuser.
    log "  Running srun --nodes=2 --ntasks-per-node=1 hostname as testuser on login1 ..."
    SRUN_OUTPUT=$($SSH_MGMT "ssh $SSH_OPTS bluebanquise@login1 'sudo su - testuser -c \"srun --nodes=2 --ntasks-per-node=1 hostname\"'")

    log "  srun output:"
    echo "$SRUN_OUTPUT"

    # Validate output contains both compute node hostnames.
    if echo "$SRUN_OUTPUT" | grep -q "c001" && echo "$SRUN_OUTPUT" | grep -q "c002"; then
        log "  [$distro] SLURM TEST: SUCCESS — job ran on c001 and c002."
    else
        log "  [$distro] SLURM TEST: FAILED — expected c001 and c002 in output."
        log "  Got: $SRUN_OUTPUT"
        exit 1
    fi

    STEP=16
fi
