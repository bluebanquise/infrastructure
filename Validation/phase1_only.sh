#!/usr/bin/env bash
# Redeploy mgt1 only (Phase 1 of launch_v3.sh), without entering the per-distro loop.
set -e

LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$LAUNCH_CURRENT_DIR/values_v3.sh"

STEPS_DIR="$LAUNCH_CURRENT_DIR/steps_v3"
source "$STEPS_DIR/common.sh"

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/01_setup_networks.sh"

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/02_start_http_server.sh"

cd "$LAUNCH_CURRENT_DIR"
source "$STEPS_DIR/03_bootstrap_mgt1.sh"

cd "$LAUNCH_CURRENT_DIR"
export MGT1_IP=$(virsh net-dhcp-leases default | grep "$MGT1_MAC_VIRBR0" | tail -1 | awk '{print $5}' | sed 's|/.*||')
log "mgt1 IP: $MGT1_IP"

source "$STEPS_DIR/04_deploy_bb_on_mgt1.sh"

log "Phase 1 (mgt1 rebuild) complete."
