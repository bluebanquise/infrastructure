#!/usr/bin/env bash
# Per-distro configuration and shared helpers.
# Sourced by every per_distro step script.

# ---------------------------------------------------------------------------
# Per-distro static configuration
# ---------------------------------------------------------------------------

declare -A DISTRO_VM_NAME
DISTRO_VM_NAME[rhel9]=mgmt_rhel9
DISTRO_VM_NAME[rhel10]=mgmt_rhel10
DISTRO_VM_NAME[ubuntu24]=mgmt_ubuntu24
DISTRO_VM_NAME[debian13]=mgmt_debian13

# IP of the mgmt VM on virbr1 (assigned by mgt1 DHCP via MAC).
declare -A DISTRO_MGMT_VIRBR1_IP
DISTRO_MGMT_VIRBR1_IP[rhel9]=10.10.0.21
DISTRO_MGMT_VIRBR1_IP[rhel10]=10.10.0.22
DISTRO_MGMT_VIRBR1_IP[ubuntu24]=10.10.0.23
DISTRO_MGMT_VIRBR1_IP[debian13]=10.10.0.24

# MACs for the mgmt VM on virbr1 (used by mgt1 DHCP for static assignment).
declare -A DISTRO_MGMT_MAC_VIRBR1
DISTRO_MGMT_MAC_VIRBR1[rhel9]=52:54:00:bb:09:01
DISTRO_MGMT_MAC_VIRBR1[rhel10]=52:54:00:bb:10:01
DISTRO_MGMT_MAC_VIRBR1[ubuntu24]=52:54:00:bb:24:01
DISTRO_MGMT_MAC_VIRBR1[debian13]=52:54:00:bb:13:01

# MACs for the mgmt VM on virbr2 (cluster network).
declare -A DISTRO_MGMT_MAC_VIRBR2
DISTRO_MGMT_MAC_VIRBR2[rhel9]=52:54:00:cc:09:01
DISTRO_MGMT_MAC_VIRBR2[rhel10]=52:54:00:cc:10:01
DISTRO_MGMT_MAC_VIRBR2[ubuntu24]=52:54:00:cc:24:01
DISTRO_MGMT_MAC_VIRBR2[debian13]=52:54:00:cc:13:01

# ISO filenames (downloaded to http/ on the host).
declare -A DISTRO_ISO_NAME
DISTRO_ISO_NAME[rhel9]=AlmaLinux-9-latest-x86_64-dvd.iso
DISTRO_ISO_NAME[rhel10]=AlmaLinux-10-latest-x86_64-dvd.iso
DISTRO_ISO_NAME[ubuntu24]=ubuntu-24.04-live-server-amd64.iso
DISTRO_ISO_NAME[debian13]=debian-testing-amd64-netinst.iso

# ISO download URLs.
declare -A DISTRO_ISO_URL
DISTRO_ISO_URL[rhel9]=https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso
DISTRO_ISO_URL[rhel10]=https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10-latest-x86_64-dvd.iso
DISTRO_ISO_URL[ubuntu24]=https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
DISTRO_ISO_URL[debian13]=https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso

# virt-install --os-variant value.
declare -A DISTRO_OS_VARIANT
DISTRO_OS_VARIANT[rhel9]=rhel8-unknown
DISTRO_OS_VARIANT[rhel10]=rhel8-unknown
DISTRO_OS_VARIANT[ubuntu24]=ubuntu24.04
DISTRO_OS_VARIANT[debian13]=debian12

# Extra virt-install boot flags (EFI for RHEL, empty for others).
declare -A DISTRO_BOOT_FLAGS
DISTRO_BOOT_FLAGS[rhel9]="--boot firmware=efi,firmware.feature0.enabled=no,firmware.feature0.name=secure-boot"
DISTRO_BOOT_FLAGS[rhel10]="--boot firmware=efi,firmware.feature0.enabled=no,firmware.feature0.name=secure-boot"
DISTRO_BOOT_FLAGS[ubuntu24]=""
DISTRO_BOOT_FLAGS[debian13]=""

# Extra virsh undefine flags (RHEL needs --nvram for EFI).
declare -A DISTRO_UNDEFINE_FLAGS
DISTRO_UNDEFINE_FLAGS[rhel9]=--nvram
DISTRO_UNDEFINE_FLAGS[rhel10]=--nvram
DISTRO_UNDEFINE_FLAGS[ubuntu24]=""
DISTRO_UNDEFINE_FLAGS[debian13]=""

# Initial SSH user created by the OS installer (used before BB bootstrap).
declare -A DISTRO_INITIAL_USER
DISTRO_INITIAL_USER[rhel9]=bluebanquise
DISTRO_INITIAL_USER[rhel10]=bluebanquise
DISTRO_INITIAL_USER[ubuntu24]=bluebanquise
DISTRO_INITIAL_USER[debian13]=bluebanquise

# Pre-bootstrap commands run on the mgmt VM before online_bootstrap.sh.
# These install EPEL on RHEL and update packages everywhere.
declare -A DISTRO_PRE_BOOTSTRAP
DISTRO_PRE_BOOTSTRAP[rhel9]='sudo dnf install -y epel-release && sudo dnf update -y'
DISTRO_PRE_BOOTSTRAP[rhel10]='sudo dnf install -y epel-release && sudo dnf update -y'
DISTRO_PRE_BOOTSTRAP[ubuntu24]='sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'
DISTRO_PRE_BOOTSTRAP[debian13]='sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'

# Cluster nodes (fixed for all distros since runs are sequential).
export CLUSTER_MGMT_IP=10.20.0.1
export CLUSTER_LOGIN1_IP=10.20.0.2
export CLUSTER_C001_IP=10.20.0.3
export CLUSTER_C002_IP=10.20.0.4

export CLUSTER_LOGIN1_MAC=52:54:00:cc:00:10
export CLUSTER_C001_MAC=52:54:00:cc:00:11
export CLUSTER_C002_MAC=52:54:00:cc:00:12

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# SSH shortcuts built at runtime from distro-specific IPs.
# Call setup_ssh_aliases <distro> after sourcing common.sh to populate these.
setup_ssh_aliases() {
    local distro=$1
    local mgmt_ip=${DISTRO_MGMT_VIRBR1_IP[$distro]}
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    SSH_MGT1="ssh $ssh_opts bluebanquise@${MGT1_IP}"
    SCP_MGT1="scp $ssh_opts"

    # Host → mgmt VM via ProxyJump through mgt1.
    SSH_MGMT="ssh $ssh_opts -J bluebanquise@${MGT1_IP} bluebanquise@${mgmt_ip}"
    SCP_MGMT="scp $ssh_opts -J bluebanquise@${MGT1_IP}"
}

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}
