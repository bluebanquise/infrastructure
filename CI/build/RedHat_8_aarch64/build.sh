set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep rockylinux_8_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/rockylinux/rockylinux:8
  podman build --no-cache --tag rockylinux_8_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/el8/aarch64/" ]]; then
rm -Rf ~/build/el8/aarch64/
fi
mkdir -p ~/build/el8/aarch64/

if [ "$1" == "all" ]; then
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build nyancat RedHat 8
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_8_build prometheus RedHat 8
# podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build ansible-cmdb RedHat 8
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build slurm RedHat 8
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build atftp RedHat 8
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build bluebanquise-ipxe RedHat 8
# podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build bluebanquise-tools RedHat 8
# podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build ssh-wait RedHat 8
# podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS rockylinux_8_build colour_text RedHat 8
else
podman run -it --rm -v ~/build/el8/aarch64/:/root/rpmbuild/RPMS -v /tmp:/tmp rockylinux_8_build $1 RedHat 8
fi
