set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
docker images | grep ubuntu_24.04_build
if [ $? -ne 0 ]; then
  set -e
  docker pull docker.io/ubuntu:24.04
  docker build --no-cache --tag ubuntu_24.04_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "~/build/ubuntu2404/arm64/" ]]; then
rm -Rf ~/build/ubuntu2404/arm64/
fi
mkdir -p ~/build/ubuntu2404/arm64/

if [ "$1" == "all" ]; then
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build nyancat Ubuntu 24.04 # --privileged is used here to prevent a crash, should migrate podman to docker to fix this
#docker run --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build conman Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build prometheus Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build atftp Ubuntu 24.04
# docker run --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS ubuntu_24.04_build ansible-cmdb Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build slurm Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build bluebanquise-ipxe Ubuntu 24.04
# docker run --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS ubuntu_24.04_build bluebanquise-tools Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build grubby Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build loki Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build alpine Ubuntu 24.04
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build clonezilla Ubuntu 24.04

else
docker run --privileged --rm -v ~/build/ubuntu2404/arm64/:/root/debbuild/DEBS -v /tmp:/tmp ubuntu_24.04_build $1 Ubuntu 24.04
fi
