set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e


if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep ubuntu_20.04_build_amd64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag ubuntu_20.04_build_amd64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/ubuntu2004/x86_64/" ]]; then
rm -Rf $HOME/CI/build/ubuntu2004/x86_64/
fi
mkdir -p $HOME/CI/build/ubuntu2004/x86_64/


if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 nyancat Ubuntu 20.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 conman Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 prometheus Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 atftp Ubuntu 20.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build_amd64 ansible-cmdb Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 slurm Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 bluebanquise-ipxe Ubuntu 20.04
#docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS ubuntu_20.04_build_amd64 bluebanquise-tools Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 grubby Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 loki Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 alpine Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 clonezilla Ubuntu 20.04
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 memtest86plus Ubuntu 20.04

else
docker run --rm $PLATFORM -v $HOME/CI/build/ubuntu2004/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp ubuntu_20.04_build_amd64 $1 Ubuntu 20.04
fi
