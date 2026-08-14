#!/usr/bin/env bash
# On the per-distro mgmt VM, download the cluster OS ISO, mount it,
# and run bluebanquise-bootset for login1, c001, and c002.

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

ISO_NAME=${DISTRO_ISO_NAME[$distro]}
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if (( STEP < 13 )); then
    log "13 [$distro] Prepare PXE on mgmt VM for cluster nodes."

    # Download ISO onto mgmt VM from the host HTTP server (via mgt1 gateway).
    log "  Downloading $ISO_NAME onto mgmt VM ..."
    $SSH_MGMT "wget -q -nc http://$HOST_IP:$HOST_HTTP_PORT/$ISO_NAME -P /var/lib/bluebanquise/"

    # Install the netboot via the official tool (airgapped: --netboot points
    # at the ISO already uploaded above, so it never touches the internet)
    # and run bluebanquise-bootset for each cluster node.
    NETBOOT_ID=${DISTRO_NETBOOT_ID[$distro]}
    log "  Installing netboot ($NETBOOT_ID) and running bootset ..."
    $SSH_MGMT << EOF
set -e
PYTHONPATH=\$(pip3 show ClusterShell 2>/dev/null | grep Location | awk '{print \$2}')
sudo bluebanquise-netboots-installer install $NETBOOT_ID $DISTRO_NETBOOT_ARCH --netboot /var/lib/bluebanquise/$ISO_NAME -q
export PYTHONPATH=\$PYTHONPATH
sudo bluebanquise-bootset -n login1 -b osdeploy
sudo bluebanquise-bootset -n c001   -b osdeploy
sudo bluebanquise-bootset -n c002   -b osdeploy
sudo mkdir -p /var/www/html/preboot_execution_environment/
sudo ln -sf ../pxe/convergence.ipxe /var/www/html/preboot_execution_environment/convergence.ipxe
EOF

    log "  PXE ready for login1, c001, c002."
    STEP=13
fi
