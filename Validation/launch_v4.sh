#!/usr/bin/env bash
# BlueBanquise end-to-end cluster validation, v4.
#
# For each supported distribution, one single-distro cluster:
#   10. Install the management VM from the distribution ISO with its native
#       unattended file (kickstart, preseed, autoinstall, Agama), like an admin
#       installing the first server of a cluster from a USB key
#   11. Bootstrap BlueBanquise on it the documented way (online_bootstrap.sh)
#   12. Deploy the management stack (DHCP, DNS, PXE, NFS, Slurm, gateway, ...)
#   13. Install the distribution netboot, set nodes to OS deployment
#   14. PXE-deploy login1, c001, c002 from the management VM
#   15. Configure the nodes with Ansible
#   16. Run a Slurm job as testuser from login1 on c001 and c002
#   17. Remove all VMs of the run
#
# The run stops at the first failure, with the VMs left in place. Fix, then
# resume from the failed step, e.g.:
#   STEP=11 CURRENT_DISTRO=rhel10 ./launch_v4.sh
# Run a subset of distributions:
#   DISTROS="debian13 ubuntu26" ./launch_v4.sh
# Stop after a given step (e.g. to prepare a mgmt VM only):
#   DISTROS="leap16" STOP_AFTER=11 ./launch_v4.sh

set -e

LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$LAUNCH_CURRENT_DIR/values_v4.sh"

STEPS_DIR="$LAUNCH_CURRENT_DIR/steps_v4"
source "$STEPS_DIR/common.sh"

# On failure (set -e, or an explicit exit 1 in a step), say where to resume.
trap 'rc=$?; if [ $rc -ne 0 ]; then log "FAILED in ${step:-host setup} (${distro:-no distro}). VMs left in place. Resume with: STEP=$STEP CURRENT_DISTRO=${distro:-} ./launch_v4.sh"; fi' EXIT

# ---------------------------------------------------------------------------
# Host setup
# ---------------------------------------------------------------------------

mkdir -p "$ISO_DIR" "$UNATTENDED_DIR" "$IMAGES_DIR"
source "$STEPS_DIR/01_setup_networks.sh"

# ---------------------------------------------------------------------------
# One cluster per distribution
# ---------------------------------------------------------------------------

# Allow resuming at a specific distro (e.g. CURRENT_DISTRO=rhel10).
SKIP=false
if [ -n "${CURRENT_DISTRO:-}" ]; then
    SKIP=true
fi

for distro in "${DISTROS[@]}"; do

    if $SKIP && [ "$distro" != "$CURRENT_DISTRO" ]; then
        log "Skipping $distro (resuming from $CURRENT_DISTRO)."
        continue
    fi
    SKIP=false

    # Each distro starts at step 10, unless resuming mid-distro.
    if (( STEP < 10 )); then
        STEP=9
    fi

    log "========================================================"
    log " Starting validation for: $distro"
    log "========================================================"

    for step in 10_install_mgmt 11_bootstrap_bb_on_mgmt 12_deploy_management_stack \
                13_prepare_pxe_for_cluster 14_pxe_deploy_cluster_nodes \
                15_deploy_node_stacks 16_test_slurm 17_cleanup_distro; do
        cd "$LAUNCH_CURRENT_DIR"
        source "$STEPS_DIR/per_distro/$step.sh" "$distro"
        if [ -n "${STOP_AFTER:-}" ] && (( STEP >= STOP_AFTER )); then
            log "[$distro] Stopping after step $STEP (STOP_AFTER=$STOP_AFTER), VMs left in place."
            exit 0
        fi
    done

    log "[$distro] RESULT: PASS"
    STEP=9
done

log "========================================================"
log " Validation complete: ALL PASS (${DISTROS[*]})"
log "========================================================"
