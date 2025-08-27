set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep ubuntu_22.04_build_amd64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag ubuntu_22.04_build_amd64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/ubuntu2204/x86_64/" ]]; then
rm -Rf $HOME/CI/build/ubuntu2204/x86_64/
fi
mkdir -p $HOME/CI/build/ubuntu2204/x86_64/



if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 nyancat Ubuntu 22.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 conman Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 prometheus Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 atftp Ubuntu 22.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS ubuntu_22.04_build_amd64 ansible-cmdb Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 slurm Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 bluebanquise-ipxe Ubuntu 22.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS ubuntu_22.04_build_amd64 bluebanquise-tools Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 grubby Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 loki Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 alpine Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 clonezilla Ubuntu 22.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 memtest86plus Ubuntu 22.04

else
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2204/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_22.04_build_amd64 $1 Ubuntu 22.04
fi
