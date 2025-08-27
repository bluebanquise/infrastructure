set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep debian_12_build_amd64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag debian_12_build_amd64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/debian12/x86_64/" ]]; then
rm -Rf $HOME/CI/build/debian12/x86_64/
fi
mkdir -p $HOME/CI/build/debian12/x86_64/

if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 nyancat Debian 12
#docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 conman Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 prometheus Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 atftp Debian 12
# docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS debian_12_build_amd64 ansible-cmdb Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 slurm Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 bluebanquise-ipxe Debian 12
# docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS debian_12_build_amd64 bluebanquise-tools Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 grubby Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 loki Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 alpine Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 clonezilla Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 memtest86plus Debian 12
else
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/x86_64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build_amd64 $1 Debian 12
fi
