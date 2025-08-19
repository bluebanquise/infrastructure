set -x
#if [ "$1" == 'yes' ]; then
podman run --rm -v /home/bluebanquise/repositories/ubuntu2404/x86_64/bluebanquise/:/repo/ ubuntu:24.04 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get install -y dpkg-dev reprepro; \
    cd /repo/; \
    rm -Rf repo; \
    mkdir repo && cd repo && mkdir conf -p; \
    echo "Origin: BlueBanquise" > conf/distributions; \
    echo "Label: bluebanquise" >> conf/distributions; \
    echo "Codename: noble" >> conf/distributions; \
    echo "Suite: stable" >> conf/distributions; \
    echo "Architectures: amd64" >> conf/distributions; \
    echo "Components: main" >> conf/distributions; \
    cd /repo/packages/x86_64/; \
    reprepro -b /repo/repo/ includedeb noble *.deb; \
    cd ../noarch/; \
    reprepro -b /repo/repo/ includedeb noble *.deb; \
    reprepro -b /repo/repo/ list noble; \
    '
# else
# podman run --rm -v /home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/:/repo/ ubuntu:20.04 /bin/bash -c ' \
#     set -x ; \
#     apt-get update ; \
#     apt-get install -y wget dpkg-dev apt-mirror rsync ; \
#     #wget http://bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/x86_64/bluebanquise/bluebanquise.list ; \
#     # echo "deb [trusted=yes] http://bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/x86_64/bluebanquise/ ./" > bluebanquise.list ; \
#     #apt-mirror bluebanquise.list ; \
#     wget -np -nH --cut-dirs 5 -r --reject "index.html*" http://bluebanquise.com/repository/releases/latest/ubuntu2004/x86_64/bluebanquise/ ; \
#     rsync -a -v --ignore-times bluebanquise/packages/* /repo/packages/ ; \
#     cd /repo/; \
#     dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
#     '
# fi
