set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep ubuntu_20.04_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/ubuntu:20.04
  podman build --no-cache --tag ubuntu_20.04_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/ubuntu2004/x86_64/" ]]; then
rm -Rf ~/build/ubuntu2004/x86_64/
fi
mkdir -p ~/build/ubuntu2004/x86_64/

if [ "$1" == "all" ]; then
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build nyancat Ubuntu 20.04
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_20.04_build prometheus Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build ansible-cmdb Ubuntu 20.04
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build slurm Ubuntu 20.04
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build bluebanquise-ipxe Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build bluebanquise-tools Ubuntu 20.04
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build grubby Ubuntu 20.04
else
podman run -it --rm -v ~/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build $1 Ubuntu 20.04
fi
