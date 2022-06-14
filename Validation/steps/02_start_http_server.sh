CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo " 02 Start http server."
(
cd $CURRENT_DIR/../http
python3 -m http.server 8000
) &
export http_server_pid=$!
echo "  - http server pid: $http_server_pid"