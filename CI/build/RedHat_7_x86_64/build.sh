set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
podman images | grep centos_7_build
if [ $? -ne 0 ]; then
  set -e
  podman pull docker.io/centos:7
  podman build --no-cache --tag centos_7_build -f $CURRENT_DIR/Dockerfile
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

if [ "$1" == "all" ]; then
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build nyancat RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build prometheus RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build ansible-cmdb RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build slurm RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build atftp RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build bluebanquise-ipxe RedHat 7
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build bluebanquise-tools RedHat 7
else
podman run -it --rm -v ~/build/el7/x86_64/:/root/rpmbuild/RPMS -v ~/build/el7/sources/:/root/rpmbuild/SRPMS/ centos_7_build $1 RedHat 7
fi
