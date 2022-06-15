echo
#trap "kill -9 $(ps -ax | grep 'http.server 8000' | sed 2d | awk -F ' ' '{print $1}')" EXIT
echo "Starting test."
set -e
source values.sh
source steps/01_setup_networks.sh
source steps/02_start_http_server.sh
source steps/03_bootstrap_mgt1.sh
source steps/04_deploy_bluebanquise_on_mgt1.sh
