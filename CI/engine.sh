CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Assume arm64_worker and x86_64_worker both resolve

mkdir ~/CI/
mkdir -p ~/CI/{build,repositories}/{el7,el8}/{x86_64,aarch64}/
mkdir -p ~/CI/{build,repositories}/{ubuntu2004}/{x86_64,arm64}/

# BUILDS

rsync -a $CURRENT_DIR/build/RedHat_8_x86_64 jenkins@x86_64_worker:/home/jenkins/RedHat_8_x86_64