set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep opensuse_leap_15_build_arm64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag opensuse_leap_15_build_arm64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/lp15/aarch64/" ]]; then
rm -Rf $HOME/CI/build/lp15/aarch64/
fi
mkdir -p $HOME/CI/build/lp15/aarch64/

if [[ -d "$HOME/CI/build/lp15/sources/" ]]; then
rm -Rf $HOME/CI/build/lp15/sources/
fi
mkdir -p $HOME/CI/build/lp15/sources/


if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 nyancat opensuse_leap 15
#docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 conman opensuse_leap 15
# docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build_arm64 ansible-cmdb opensuse_leap 15
# docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build_arm64 atftp opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 bluebanquise-ipxe opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 atftp opensuse_leap 15
# docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build_arm64 bluebanquise-tools opensuse_leap 15
# docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 slurm opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 prometheus opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 loki opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 clonezilla opensuse_leap 15
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp opensuse_leap_15_build_arm64 alpine opensuse_leap 15

else
docker run --rm $PLATFORM -v $HOME/CI/build/lp15/aarch64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v $HOME/CI/tmp/:/tmp  opensuse_leap_15_build_arm64 $1 opensuse_leap 15
fi
