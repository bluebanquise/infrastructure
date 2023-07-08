set -x
# if [ "$1" == 'yes' ]; then
podman run -it --rm -v /home/bluebanquise/repositories/debian12/x86_64/bluebanquise/:/repo/ debian:12 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt install -y dpkg-dev reprepro; \
    cd /repo/; \
    rm -Rf repo; \
    mkdir repo && cd repo && mkdir conf -p; \
    echo "Origin: BlueBanquise" > conf/distributions; \
    echo "Label: bluebanquise" >> conf/distributions; \
    echo "Codename: bookworm" >> conf/distributions; \
    echo "Suite: stable" >> conf/distributions; \
    echo "Architectures: amd64" >> conf/distributions; \
    echo "Components: main" >> conf/distributions; \
    cd /repo/packages/x86_64/; \
    reprepro -b /repo/repo/ includedeb bookworm *.deb; \
    cd ../noarch/; \
    reprepro -b /repo/repo/ includedeb bookworm *.deb; \
    reprepro -b /repo/repo/ list bookworm; \
    '
