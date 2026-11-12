#!/usr/bin/env bash
# Validate the cluster end to end: as testuser on login1, run
#   srun --nodes=2 --ntasks-per-node=1 uname -n
# and check that both c001 and c002 answered. Needs DHCP/DNS/NFS homes/
# users/munge/Slurm all working together.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

if (( STEP < 16 )); then
    log "16 [$distro] Slurm validation test."

    log "  Waiting for 2 idle Slurm nodes (5 min max) ..."
    READY=0
    for i in $(seq 1 30); do
        READY=$($SSH_MGMT "sinfo --noheader -o '%D %T' 2>/dev/null | awk '\$2==\"idle\" {n+=\$1} END {print n+0}'")
        [ "$READY" -ge 2 ] && break
        sleep 10
    done
    if [ "$READY" -lt 2 ]; then
        log "  Slurm not ready after 5 minutes:"
        $SSH_MGMT "sinfo; scontrol show nodes | grep -E 'NodeName|State|Reason'" || true
        exit 1
    fi

    log "  Running srun as testuser on login1 ..."
    SRUN_OUTPUT=$($SSH_MGMT "ssh login1 'sudo su - testuser -c \"srun --nodes=2 --ntasks-per-node=1 uname -n\"'")
    echo "$SRUN_OUTPUT"

    if echo "$SRUN_OUTPUT" | grep -q "^c001" && echo "$SRUN_OUTPUT" | grep -q "^c002"; then
        log "  [$distro] SLURM TEST: SUCCESS, job ran on c001 and c002."
    else
        log "  [$distro] SLURM TEST: FAILED, expected c001 and c002 in output."
        exit 1
    fi

    STEP=16
fi
