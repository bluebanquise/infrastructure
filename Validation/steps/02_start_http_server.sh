CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( $STEP < 2 )); then

    echo " 02 Start http server."
    echo "   - Grabing isos"
    cd $CURRENT_DIR/../http
    mkdir isos
    cd isos
    wget -nc https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso
    cd ../
    echo "   - Extracting boot files"
    sudo mkdir /bbmnt
    sudo mount isos/ubuntu-22.04.1-live-server-amd64.iso /bbmnt
    mkdir kernels
exit
    cp -a /bbmnt/
    (
    cd $CURRENT_DIR/../http
    python3 -m http.server 8000 > http_server.log 2>&1
    ) &
    export http_server_pid=$!
    echo "  - http server pid: $http_server_pid"

fi