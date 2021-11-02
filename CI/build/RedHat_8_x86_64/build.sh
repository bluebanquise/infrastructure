set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

podman images | grep rockylinux_8_build
if [ $? -ne 0 ]; then
  podman pull docker.io/rockylinux/rockylinux:8
  podman build --no-cache --tag rockylinux_8_build -f $CURRENT_DIR/Dockerfile
fi

podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build nyancat RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build prometheus RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build ansible-cmdb RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build slurm RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build atftp RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build ipxe-bluebanquise RedHat 8
##podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build 10 RedHat 8 1.4
## Delayed to 1.6 podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build 14 RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build ssh-wait RedHat 8
#podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux_8_build colour_text RedHat 8
## Check packages can be installed
##podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux/rockylinux:8 /bin/bash -c 'dnf install epel-release -y; dnf install dnf-plugins-core -y; dnf config-manager --set-enabled powertools; dnf install -y /root/rpmbuild/RPMS/noarch/*.rpm /root/rpmbuild/RPMS/x86_64/*.rpm'
##podman run -it --rm -v /nfs/build/el8/x86_64:/root/rpmbuild/RPMS rockylinux/rockylinux:8 /bin/bash -c 'dnf install -y git ; mkdir /infra; git clone https://github.com/oxedions/infrastructure.git /infra ; chmod +x /infra/auto_builder.sh ; auto_builder.sh 0 RedHat 8 ; dnf install -y /root/rpmbuild/RPMS/noarch/*.rpm /root/rpmbuild/RPMS/x86_64/*.rpm'
