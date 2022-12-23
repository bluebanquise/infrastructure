echo
LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
#sudo apt-get update && sudo apt-get install -y qemu-kvm virt-manager libvirt-daemon-system virtinst libvirt-clients bridge-utils
#sudo systemctl enable libvirtd
#sudo systemctl start libvirtd
#sudo usermod -aG kvm $USER
#sudo usermod -aG libvirt $USER
#newgrp kvm
#newgrp libvirt
#trap "kill -9 $(ps -ax | grep 'http.server 8000' | sed 2d | awk -F ' ' '{print $1}')" EXIT
echo "Starting test."
set -e
source values.sh
wget -nc https://repo.almalinux.org/almalinux/8/isos/x86_64/AlmaLinux-8-latest-x86_64-dvd.iso
source steps/01_setup_networks.sh
cd $LAUNCH_CURRENT_DIR
source steps/02_start_http_server.sh
cd $LAUNCH_CURRENT_DIR
source steps/03_bootstrap_mgt1.sh
cd $LAUNCH_CURRENT_DIR
source steps/04_deploy_bluebanquise_on_mgt1.sh
