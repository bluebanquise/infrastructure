#!/usr/bin/env bash
# BlueBanquise end-to-end cluster validation — v3
#
# For each supported distribution this script:
#   1. Deploys a cluster management VM via PXE from the permanent mgt1 host
#   2. Bootstraps BlueBanquise on it (branch controlled by BB_BRANCH in values_v3.sh)
#   3. Deploys the full management stack (DHCP, DNS, PXE, NFS, Slurm, …)
#   4. PXE-deploys login1, c001, c002 from the cluster management VM
#   5. Configures all cluster nodes via Ansible
#   6. Runs a Slurm job as testuser to validate the full stack
#   7. Destroys all cluster VMs and moves to the next distribution
#
# Resume from a specific step by setting STEP=<n> in the environment before
# running, e.g.:  STEP=11 CURRENT_DISTRO=rhel9 ./launch_v3.sh
#
# Step numbers:
#   1  = networks, 2 = http server, 3 = mgt1 install, 4 = mgt1 BB
#   10 = PXE deploy mgmt VM, 11 = BB bootstrap on mgmt VM
#   12 = management stack, 13 = PXE prep for cluster nodes
#   14 = PXE deploy cluster nodes, 15 = node stacks
#   16 = Slurm test, 17 = cleanup (runs unconditionally)

set -e

LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$LAUNCH_CURRENT_DIR/values_v3.sh"

STEPS_DIR="$LAUNCH_CURRENT_DIR/steps_v3"
source "$STEPS_DIR/common.sh"

# ---------------------------------------------------------------------------
# Phase 1 — one-time infrastructure setup
# ---------------------------------------------------------------------------

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/01_setup_networks.sh"

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/02_start_http_server.sh"

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/03_bootstrap_mgt1.sh"

cd "$LAUNCH_CURRENT_DIR"
# Discover mgt1 IP (needed for all subsequent steps).
export MGT1_IP=$(virsh net-dhcp-leases default | grep "$MGT1_MAC_VIRBR0" | tail -1 | awk '{print $5}' | sed 's|/.*||')
log "mgt1 IP: $MGT1_IP"

source "$STEPS_DIR/04_deploy_bb_on_mgt1.sh"

# ---------------------------------------------------------------------------
# Phase 2 — per-distro cluster validation loop
# ---------------------------------------------------------------------------

# Allow resuming at a specific distro (e.g. CURRENT_DISTRO=rhel10).
START_DISTRO=${CURRENT_DISTRO:-}
SKIP=false
if [ -n "$START_DISTRO" ]; then
    SKIP=true
fi

OVERALL_RESULT=0

for distro in "${DISTROS[@]}"; do

    if $SKIP && [ "$distro" != "$START_DISTRO" ]; then
        log "Skipping $distro (resuming from $START_DISTRO)."
        continue
    fi
    SKIP=false

    # Reset per-distro step to 9 unless we're resuming mid-distro.
    if (( STEP < 10 )); then
        STEP=9
    fi

    log "========================================================"
    log " Starting validation for: $distro"
    log "========================================================"

    # Rebuild SSH aliases with mgt1 IP and distro-specific mgmt IP.
    setup_ssh_aliases "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/10_pxe_deploy_cluster_mgmt.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/11_bootstrap_bb_on_mgmt.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/12_deploy_management_stack.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/13_prepare_pxe_for_cluster.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/14_pxe_deploy_cluster_nodes.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/15_deploy_node_stacks.sh" "$distro"

    cd "$LAUNCH_CURRENT_DIR"
    set +e
    source "$STEPS_DIR/per_distro/16_test_slurm.sh" "$distro"
    DISTRO_RESULT=$?
    set -e

    # Cleanup always runs regardless of test result.
    cd "$LAUNCH_CURRENT_DIR"
    source "$STEPS_DIR/per_distro/17_cleanup_distro.sh" "$distro"

    if [ $DISTRO_RESULT -eq 0 ]; then
        log "[$distro] RESULT: PASS"
    else
        log "[$distro] RESULT: FAIL"
        OVERALL_RESULT=1
    fi

    log "========================================================"
done

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------

log ""
log "========================================================"
log " Validation complete."
if [ $OVERALL_RESULT -eq 0 ]; then
    log " OVERALL RESULT: ALL PASS"
else
    log " OVERALL RESULT: ONE OR MORE DISTRIBUTIONS FAILED"
fi
log "========================================================"

exit $OVERALL_RESULT
