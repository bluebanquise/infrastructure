set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep debian_12_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/debian:12
  podman build --no-cache --tag debian_12_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/debian12/x86_64/" ]]; then
rm -Rf ~/build/debian12/x86_64/
fi
mkdir -p ~/build/debian12/x86_64/

if [ "$1" == "all" ]; then
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build nyancat Debian 12
#podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build conman Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build prometheus Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build atftp Debian 12
# podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS debian_12_build ansible-cmdb Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build slurm Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build bluebanquise-ipxe Debian 12
# podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS debian_12_build bluebanquise-tools Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build grubby Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build loki Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build alpine Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build clonezilla Debian 12
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build memtest86plus Debian 12
else
podman run -it --rm -v ~/build/debian12/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp debian_12_build $1 Debian 12
fi
