set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

docker images | grep rockylinux_9_build_arm64
if [ $? -ne 0 ]; then
  set -e
  docker build $PLATFORM --no-cache --tag rockylinux_9_build_arm64 -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "$HOME/CI/build/el9/aarch64/" ]]; then
rm -Rf $HOME/CI/build/el9/aarch64/
fi
mkdir -p $HOME/CI/build/el9/aarch64/


if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 nyancat RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 conman RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 powerman RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 prometheus RedHat 9
# docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build_arm64 ansible-cmdb RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 slurm RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 atftp RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 bluebanquise-ipxe RedHat 9
# docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build_arm64 bluebanquise-tools RedHat 9
# docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build_arm64 ssh-wait RedHat 9
# docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build_arm64 colour_text RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 loki RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 clonezilla RedHat 9
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 alpine RedHat 9

else
docker run --rm $PLATFORM -v $HOME/CI/build/el9/aarch64/:/root/rpmbuild/RPMS -v $HOME/CI/tmp/:/tmp rockylinux_9_build_arm64 $1 RedHat 9
fi
