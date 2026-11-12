#!/usr/bin/env bash
# Bootstrap BlueBanquise on the mgmt VM the documented way:
#   - OS update (and reboot), as an admin would before anything else
#   - online_bootstrap.sh and configure_environment.sh from master, with the
#     patches of steps_v4/patches/ applied (bluebanquise user, Ansible venv,
#     collection)
#   - upload of the cluster inventory and playbooks

distro=$1
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$CURRENT_DIR/../common.sh"
setup_ssh_aliases "$distro"

FAMILY=${DISTRO_FAMILY[$distro]}
VM_NAME=$(mgmt_vm_name "$distro")
INVENTORY_DIR="$CURRENT_DIR/../inventories/cluster/$distro"
COLLECTION_DIR=/var/lib/bluebanquise/.ansible/collections/ansible_collections/bluebanquise/infrastructure

if (( STEP < 11 )); then
    log "11 [$distro] Bootstrap BlueBanquise on $MGMT_IP."

    log "  OS update ..."
    case "$FAMILY" in
        redhat)
            $SSH_INSTALL "sudo dnf update -y"
            ;;
        debian|ubuntu)
            $SSH_INSTALL "sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
            ;;
        suse)
            $SSH_INSTALL "sudo zypper -n refresh && sudo zypper -n update"
            ;;
    esac
    $SSH_INSTALL "sudo systemctl reboot" || true
    sleep 20
    timeout 600 "$CURRENT_DIR/../functions/waitforssh.sh" "$INSTALL_USER@$MGMT_IP"

    # BlueBanquise tested: master, with the not yet merged fixes of patches/
    # applied. Prepared on the host (a minimal OS has no git yet).
    BB_TREE=$(mktemp -d)
    git clone -q --depth 1 https://github.com/bluebanquise/bluebanquise.git "$BB_TREE/bluebanquise"
    # A patch already merged in master is skipped (and can then be deleted).
    for patch in "$CURRENT_DIR"/../patches/*.patch; do
        [ -f "$patch" ] || continue
        if git -C "$BB_TREE/bluebanquise" apply --reverse --check "$patch" 2>/dev/null; then
            log "  $(basename "$patch") already in master, skipped."
        else
            log "  Applying $(basename "$patch") ..."
            git -C "$BB_TREE/bluebanquise" apply "$patch"
        fi
    done
    # Copied as files (a minimal OS may have no tar).
    rm -rf "$BB_TREE/bluebanquise/.git"
    $SSH_INSTALL "rm -rf bluebanquise"
    $SCP_MGMT -r "$BB_TREE/bluebanquise" "$INSTALL_USER@$MGMT_IP:"
    rm -rf "$BB_TREE"

    # online_bootstrap.sh in its two parts, so that its environment part uses
    # the patched tree instead of a fresh clone: system part (packages,
    # bluebanquise user), then configure_environment.sh as bluebanquise, as
    # online_bootstrap.sh runs it. Previous collection removed (step resumed).
    log "  Running online_bootstrap.sh --skip_environment ..."
    $SSH_INSTALL "sudo bash bluebanquise/bootstrap/online_bootstrap.sh --silent --skip_environment"
    log "  Running configure_environment.sh as bluebanquise ..."
    $SSH_INSTALL "sudo rm -rf /var/lib/bluebanquise/bluebanquise /var/lib/bluebanquise/.ansible/collections/ansible_collections/bluebanquise && \
                  sudo cp -r bluebanquise /var/lib/bluebanquise/ && \
                  sudo chown -R bluebanquise:bluebanquise /var/lib/bluebanquise/bluebanquise && \
                  sudo -u bluebanquise -H bash -c 'cd /var/lib/bluebanquise/bluebanquise/bootstrap && ./configure_environment.sh --bb_collections_local_path=/var/lib/bluebanquise/bluebanquise/collections/infrastructure'" \
                  > "$IMAGES_DIR/$VM_NAME-configure_environment.log" 2>&1

    # online_bootstrap.sh always exits 0 (its steps run in subshells logged to
    # /var/log/bluebanquise/bootstrap): check what both parts should have produced.
    if ! $SSH_INSTALL "sudo test -x /var/lib/bluebanquise/ansible_venv/bin/ansible-playbook && sudo test -d $COLLECTION_DIR/roles"; then
        log "  No Ansible venv or collection. Look at $IMAGES_DIR/$VM_NAME-configure_environment.log. Bootstrap log tail:"
        $SSH_INSTALL "sudo tail -40 /var/log/bluebanquise/bootstrap"
        exit 1
    fi

    # Let the host in as bluebanquise, with the key the installer set for the
    # admin user (configure_environment.sh created the bluebanquise one).
    $SSH_INSTALL "cat .ssh/authorized_keys | sudo tee -a /var/lib/bluebanquise/.ssh/authorized_keys > /dev/null"
    $SSH_MGMT "true"

    $SCP_MGMT "$CURRENT_DIR/../functions/waitforssh.sh" bluebanquise@"$MGMT_IP":/tmp/waitforssh.sh
    $SSH_MGMT "sudo install -m 755 /tmp/waitforssh.sh /usr/local/bin/waitforssh.sh"

    # Uploaded as "cluster_inventory", not "cluster": pxe_stack reserves
    # /var/lib/bluebanquise/cluster/ as its runtime state directory.
    log "  Uploading cluster inventory for $distro ..."
    $SSH_MGMT "rm -rf /var/lib/bluebanquise/cluster_inventory /var/lib/bluebanquise/playbooks"
    $SCP_MGMT -r "$INVENTORY_DIR" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/cluster_inventory
    $SCP_MGMT -r "$CURRENT_DIR/../playbooks" bluebanquise@"$MGMT_IP":/var/lib/bluebanquise/

    # mgmt VM's bluebanquise key goes on the PXE-installed cluster nodes.
    MGMT_PUBKEY=$($SSH_MGMT 'cat /var/lib/bluebanquise/.ssh/id_ed25519.pub')
    $SSH_MGMT "echo 'os_admin_ssh_keys=[\"$MGMT_PUBKEY\"]' >> /var/lib/bluebanquise/cluster_inventory/hosts"
    $SSH_MGMT "echo 'slurm_munge_key_b64: \"$SLURM_MUNGE_KEY_B64\"' >> /var/lib/bluebanquise/cluster_inventory/group_vars/all/slurm.yml"

    # Ansible reaches the mgmt VM itself as "mgt".
    $SSH_MGMT "grep -q ' mgt$' /etc/hosts || echo '127.0.0.1 mgt' | sudo tee -a /etc/hosts"
    $SSH_MGMT "ssh-keygen -f ~/.ssh/known_hosts -R mgt 2>/dev/null; ssh -o StrictHostKeyChecking=accept-new mgt hostname"

    log "  BlueBanquise bootstrap on $distro mgmt VM complete."
    STEP=11
fi
