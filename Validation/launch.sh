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
source steps/01_setup_networks.sh
cd $LAUNCH_CURRENT_DIR
source steps/02_start_http_server.sh
cd $LAUNCH_CURRENT_DIR
source steps/03_bootstrap_mgt1.sh
cd $LAUNCH_CURRENT_DIR
source steps/04_deploy_bluebanquise_on_mgt1.sh
exit
cd $LAUNCH_CURRENT_DIR
source steps/06_deploy_rhel8.sh
cd $LAUNCH_CURRENT_DIR
source steps/07_deploy_rhel9.sh
cd $LAUNCH_CURRENT_DIR
source steps/08_deploy_rhel7.sh
cd $LAUNCH_CURRENT_DIR
source steps/09_deploy_ubuntu20.sh
cd $LAUNCH_CURRENT_DIR
source steps/10_deploy_ubuntu22.sh
cd $LAUNCH_CURRENT_DIR
source steps/11_deploy_osl13.sh
cd $LAUNCH_CURRENT_DIR
source steps/12_deploy_debian11.sh
