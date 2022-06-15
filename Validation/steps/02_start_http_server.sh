CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if (( $STEP < 2 )); then

    echo " 02 Start http server."
    (
    cd $CURRENT_DIR/../http
    python3 -m http.server 8000 > http_server.log 2>&1
    ) &
    export http_server_pid=$!
    echo "  - http server pid: $http_server_pid"

fi