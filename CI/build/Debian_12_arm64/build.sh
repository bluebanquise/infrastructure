set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep debian_12_build
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag debian_12_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/debian12/arm64/" ]]; then
rm -Rf $HOME/CI/build/debian12/arm64/
fi
mkdir -p $HOME/CI/build/debian12/arm64/


if [ "$1" == "all" ]; then
#docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build conman Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp -v $HOME/ debian_12_build nyancat Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build prometheus Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build atftp Debian 12
# docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS debian_12_build ansible-cmdb Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build slurm Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build bluebanquise-ipxe Debian 12
# docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS debian_12_build bluebanquise-tools Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build grubby Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build loki Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build clonezilla Debian 12
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build alpine Debian 12
else
docker run --rm $PLATFORM -v $HOME/CI/build/debian12/arm64/:/root/debbuild/DEBS -v $HOME/CI/tmp/:/tmp debian_12_build $1 Debian 12
fi
