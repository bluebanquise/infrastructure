set -x
# if [ "$1" == 'yes' ]; then
docker run --rm -v $HOME/CI/repositories/debian11/x86_64/bluebanquise/:/repo/ debian:11 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt install -y dpkg-dev reprepro; \
    cd /repo/; \
    rm -Rf repo; \
    mkdir repo && cd repo && mkdir conf -p; \
    echo "Origin: BlueBanquise" > conf/distributions; \
    echo "Label: bluebanquise" >> conf/distributions; \
    echo "Codename: bullseye" >> conf/distributions; \
    echo "Suite: stable" >> conf/distributions; \
    echo "Architectures: amd64" >> conf/distributions; \
    echo "Components: main" >> conf/distributions; \
    cd /repo/packages/x86_64/; \
    reprepro -b /repo/repo/ includedeb bullseye *.deb; \
    cd ../noarch/; \
    reprepro -b /repo/repo/ includedeb bullseye *.deb; \
    reprepro -b /repo/repo/ list bullseye; \
    '
# else
# docker run --rm -v $HOME/CI/repositories/debian11/x86_64/bluebanquise/:/repo/ debian:11 /bin/bash -c ' \
#     set -x ; \
#     apt update ; \
#     apt install -y wget dpkg-dev apt-mirror rsync ; \
#     #wget http://bluebanquise.com/repository/releases/1.5-dev/debian11/x86_64/bluebanquise/bluebanquise.list ; \
#     # echo "deb [trusted=yes] http://bluebanquise.com/repository/releases/1.5-dev/debian11/x86_64/bluebanquise/ ./" > bluebanquise.list ; \
#     #apt-mirror bluebanquise.list ; \
#     wget -np -nH --cut-dirs 5 -r --reject "index.html*" http://bluebanquise.com/repository/releases/latest/debian11/x86_64/bluebanquise/ ; \
#     rsync -a -v --ignore-times bluebanquise/packages/* /repo/packages/ ; \
#     cd /repo/; \
#     dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
#     '
# fi
