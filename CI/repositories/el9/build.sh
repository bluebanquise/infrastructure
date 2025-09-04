set -x
# if [ "$1" == 'yes' ]; then
docker run --rm $PLATFORM -v $1:/repo/ $2 /bin/bash -c ' \
    set -x ; \
    createrepo /repo/
    '
# else
# docker run --rm -v $HOME/CI/repositories/el8/x86_64/bluebanquise/:/repo/ rockylinux/rockylinux:8 /bin/bash -c ' \
#     set -x ; \
#     dnf install -y wget yum-utils createrepo rsync ; \
#     wget http://bluebanquise.com/repository/releases/latest/el8/x86_64/bluebanquise/bluebanquise.repo -P /etc/yum.repos.d/ ; \
#     reposync -c /etc/yum.repos.d/bluebanquise.repo --repoid=bluebanquise -p /root/ ; \
#     rsync -a -v --ignore-times /root/bluebanquise/packages/* /repo/packages/ ; \
#     createrepo /repo/ ; \
#     '
# fi
