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
if (( $STEP < 1 )); then
    source steps/01_setup_networks.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 2 )); then
    source steps/02_start_http_server.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 3 )); then
    source steps/03_bootstrap_mgt1.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 6 )); then
    source steps/04_deploy_bluebanquise_on_mgt1.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 10 )); then
    source steps/06_deploy_rhel8.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 11 )); then
    source steps/07_deploy_rhel9.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 12 )); then
    source steps/08_deploy_rhel7.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 13 )); then
    source steps/09_deploy_ubuntu20.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 14 )); then
    source steps/10_deploy_ubuntu22.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 15 )); then
    source steps/11_deploy_osl13.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 16 )); then
    source steps/12_deploy_debian11.sh
fi
cd $LAUNCH_CURRENT_DIR
if (( $STEP < 17 )); then
    source steps/13_deploy_debian12.sh
fi