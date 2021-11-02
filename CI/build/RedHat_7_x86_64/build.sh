set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

podman images | grep centos_7_build
if [ $? -ne 0 ]; then
  podman pull docker.io/centos:7
  podman build --no-cache --tag centos_7_build -f $CURRENT_DIR/Dockerfile
fi

podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build nyancat RedHat 7
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build prometheus RedHat 7
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build ansible-cmdb RedHat 7
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build slurm RedHat 7
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build atftp RedHat 7
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS centos_7_build ipxe-bluebanquise RedHat 7
