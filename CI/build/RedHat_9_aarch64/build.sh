set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
docker images | grep rockylinux_9_build
if [ $? -ne 0 ]; then
  set -e
  docker pull docker.io/rockylinux/rockylinux:9
  docker build --no-cache --tag rockylinux_9_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "~/build/el9/aarch64/" ]]; then
rm -Rf ~/build/el9/aarch64/
fi
mkdir -p ~/build/el9/aarch64/

if [ -z ${2+x} ]; then
  PLATFORM=""
else
  PLATFORM=$2
fi

if [ "$1" == "all" ]; then
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build nyancat RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build conman RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build powerman RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build prometheus RedHat 9
# docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build ansible-cmdb RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build slurm RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build atftp RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build bluebanquise-ipxe RedHat 9
# docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build bluebanquise-tools RedHat 9
# docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build ssh-wait RedHat 9
# docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS rockylinux_9_build colour_text RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build loki RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build clonezilla RedHat 9
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build alpine RedHat 9

else
docker run --rm $PLATFORM -v ~/build/el9/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_9_build $1 RedHat 9
fi
