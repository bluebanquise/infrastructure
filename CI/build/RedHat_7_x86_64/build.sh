set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
docker images | grep centos_7_build
if [ $? -ne 0 ]; then
  set -e
  docker pull docker.io/centos:7
  docker build --no-cache --tag centos_7_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "~/build/el7/x86_64/" ]]; then
rm -Rf ~/build/el7/x86_64/
fi
mkdir -p ~/build/el7/x86_64/

if [[ -d "~/build/el7/sources/" ]]; then
rm -Rf ~/build/el7/sources/
fi
mkdir -p ~/build/el7/sources/

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build nyancat RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build conman RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build prometheus RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build slurm RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build atftp RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build bluebanquise-ipxe RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build loki RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build alpine RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build clonezilla RedHat 7
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build memtest86plus RedHat 7

else
docker run --rm $PLATFORM -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp centos_7_build $1 RedHat 7
fi
