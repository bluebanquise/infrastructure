set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi


docker images | grep centos_7_build
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag centos_7_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/el7/aarch64/" ]]; then
rm -Rf $HOME/CI/build/el7/aarch64/
fi
mkdir -p $HOME/CI/build/el7/aarch64/

if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build nyancat RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build conman RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build prometheus RedHat 7
#docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS centos_7_build ansible-cmdb RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build slurm RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build atftp RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build bluebanquise-ipxe RedHat 7
# docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS centos_7_build bluebanquise-tools RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build loki RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build alpine RedHat 7
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build clonezilla RedHat 7

else
docker run --rm $PLATFORM -v $HOME/CI/build/el7/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp centos_7_build $1 RedHat 7
fi
