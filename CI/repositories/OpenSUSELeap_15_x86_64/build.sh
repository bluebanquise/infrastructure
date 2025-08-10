set -x

# if [ "$1" == 'yes' ]; then
docker run -it --rm -v /home/bluebanquise/repositories/lp15/x86_64/bluebanquise/:/repo/ opensuse/leap:15 /bin/bash -c ' \
    set -x ; \
    zypper -n install createrepo_c ; \
    createrepo /repo/ ; \
    '
# else
# docker run -it --rm -v /home/bluebanquise/repositories/lp15/x86_64/bluebanquise/:/repo/ opensuse/leap:15 /bin/bash -c ' \
#     set -x ; \
#     zypper -n install wget yum-utils createrepo rsync ; \
#     wget http://bluebanquise.com/repository/releases/latest/lp15/x86_64/bluebanquise/bluebanquise.repo -P /etc/yum.repos.d/ ; \
#     reposync -c /etc/yum.repos.d/bluebanquise.repo --repoid=bluebanquise -p /root/ ; \
#     rsync -a -v --ignore-times /root/bluebanquise/packages/* /repo/packages/ ; \
#     createrepo /repo/ ; \
#     '
# fi
