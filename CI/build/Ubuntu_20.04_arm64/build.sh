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

if [[ -d "~/build/ubuntu2004/arm64/" ]]; then
rm -Rf ~/build/ubuntu2004/arm64/
fi
mkdir -p ~/build/ubuntu2004/arm64/

podman run -it --rm -v ~/build/ubuntu2004/arm64/:/root/debbuild/DEBS ubuntu_20.04_build nyancat Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build prometheus Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build ansible-cmdb Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build slurm Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build atftp Ubuntu 20.04
podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build ipxe-bluebanquise Ubuntu 20.04
##podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build 10 Ubuntu 20.04 1.4
## Delayed to 1.6 podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build 14 Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build ssh-wait Ubuntu 20.04
#podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS ubuntu_20.04_build colour_text Ubuntu 20.04
## Check packages can be installed
##podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS rockylinux/rockylinux:8 /bin/bash -c 'dnf install epel-release -y; dnf install dnf-plugins-core -y; dnf config-manager --set-enabled powertools; dnf install -y /root/debbuild/DEBS/noarch/*.rpm /root/debbuild/DEBS/x86_64/*.rpm'
##podman run -it --rm -v ~/build/ubuntu2004/arm64:/root/debbuild/DEBS rockylinux/rockylinux:8 /bin/bash -c 'dnf install -y git ; mkdir /infra; git clone https://github.com/oxedions/infrastructure.git /infra ; chmod +x /infra/auto_builder.sh ; auto_builder.sh 0 Ubuntu 20.04 ; dnf install -y /root/debbuild/DEBS/noarch/*.rpm /root/debbuild/DEBS/x86_64/*.rpm'
