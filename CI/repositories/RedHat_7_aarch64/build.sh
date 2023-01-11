set -x
# if [ "$1" == 'yes' ]; then
podman run -it --rm -v /home/bluebanquise/repositories/el7/aarch64/bluebanquise/:/repo/ centos:7 /bin/bash -c ' \
    set -x ; \
    yum install -y createrepo ; \
    createrepo /repo/ ; \
    '
# else
# podman run -it --rm -v /home/bluebanquise/repositories/el7/aarch64/bluebanquise/:/repo/ centos:7 /bin/bash -c ' \
#     set -x ; \
#     yum install -y wget yum-utils createrepo rsync ; \
#     wget http://bluebanquise.com/repository/releases/latest/el7/aarch64/bluebanquise/bluebanquise.repo -P /etc/yum.repos.d/ ; \
#     reposync -c /etc/yum.repos.d/bluebanquise.repo --repoid=bluebanquise -p /root/ ; \
#     rsync -a -v --ignore-times /root/bluebanquise/packages/* /repo/packages/ ; \
#     createrepo /repo/ ; \
#     '

# fi
