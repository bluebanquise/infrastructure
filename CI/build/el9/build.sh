set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

set +e
docker images | grep rockylinux_9_build_amd64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag rockylinux_9_build_amd64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

mkdir -p $HOME/CI/build/el9/x86_64/
mkdir -p $HOME/CI/build/el9/sources/

if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 nyancat RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 conman RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 powerman RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 atftp RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 bluebanquise-ipxe RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 slurm RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 prometheus RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 alpine RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 loki RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 clonezilla RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 memtest86plus RedHat 9
else
docker run --rm $PLATFORM -v $HOME/CI/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v $HOME/build/el9/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_9_build_amd64 $1 RedHat 9
fi
