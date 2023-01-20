set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep rockylinux_9_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/rockylinux/rockylinux:9
  podman build --no-cache --tag rockylinux_9_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/el9/x86_64/" ]]; then
rm -Rf ~/build/el9/x86_64/
fi
mkdir -p ~/build/el9/x86_64/

if [[ -d "~/build/el9/sources/" ]]; then
rm -Rf ~/build/el9/sources/
fi
mkdir -p ~/build/el9/sources/

if [ "$1" == "all" ]; then
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ rockylinux_9_build nyancat RedHat 9
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ rockylinux_9_build atftp RedHat 9
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ rockylinux_9_build bluebanquise-ipxe RedHat 9
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ rockylinux_9_build slurm RedHat 9
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_9_build prometheus RedHat 9
else
podman run -it --rm -v ~/build/el9/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el9/sources/:/root/rpmbuild/SRPMS/ rockylinux_9_build $1 RedHat 9
fi
