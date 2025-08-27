set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep rockylinux_8_build_amd64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag rockylinux_8_build_amd64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/el8/x86_64/" ]]; then
rm -Rf $HOME/CI/build/el8/x86_64/
fi
mkdir -p $HOME/CI/build/el8/x86_64/

if [[ -d "$HOME/CI/build/el8/sources/" ]]; then
rm -Rf $HOME/CI/build/el8/sources/
fi
mkdir -p $HOME/CI/build/el8/sources/


if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 nyancat RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 conman RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 atftp RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 bluebanquise-ipxe RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 slurm RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 prometheus RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 loki RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 alpine RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 clonezilla RedHat 8
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 memtest86plus RedHat 8

else
docker run --rm $PLATFORM -v $HOME/CI/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v $HOME/CI/tmp/:/tmp rockylinux_8_build_amd64 $1 RedHat 8
fi
