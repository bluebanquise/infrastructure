set -e
set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Assume aarch64_worker and x86_64_worker both resolve
# Assume remote user is bluebanquise user and remote home is /home/bluebanquise

# Cleanup old images
ssh bluebanquise@x86_64_worker rm -f /tmp/*x86_64.tar.xz
ssh bluebanquise@aarch64_worker mkdir -p /tmp/*aarch64.tar.xz

# Send files and run on distant target
scp $CURRENT_DIR/* bluebanquise@x86_64_worker:/tmp
scp $CURRENT_DIR/* bluebanquise@aarch64_worker:/tmp

# Execute on remote host
ssh bluebanquise@x86_64_worker "cd /tmp && ./main.sh"
ssh bluebanquise@aarch64_worker "cd /tmp && ./main.sh"

# Grab images from remote host
scp bluebanquise@x86_64_worker:/tmp/*x86_64.tar.xz /tmp
scp bluebanquise@aarch64_worker:/tmp/*aarch64.tar.xz /tmp

# Done :)