set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep debian_11_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/debian:11
  podman build --no-cache --tag debian_11_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/debian11/arm64/" ]]; then
rm -Rf ~/build/debian11/arm64/
fi
mkdir -p ~/build/debian11/arm64/

if [ "$1" == "all" ]; then
#podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build conman Debian 11
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build nyancat Debian 11
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build prometheus Debian 11
# podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS debian_11_build ansible-cmdb Debian 11
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build slurm Debian 11
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build bluebanquise-ipxe Debian 11
# podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS debian_11_build bluebanquise-tools Debian 11
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build grubby Debian 11
else
podman run -it --rm -v ~/build/debian11/arm64/:/root/debbuild/DEBS -v /tmp:/tmp debian_11_build $1 Debian 11
fi
