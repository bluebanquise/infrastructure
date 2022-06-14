#!/bin/bash
# prepare infra
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo " 01 Setup networks."
echo "  - Creating VMs private network."
virsh net-list --all | grep private_network > /dev/null
if [ $? -ne 0 ]; then
    set -e
    virsh net-define $CURRENT_DIR/../vms/private_network.xml
fi
set -e
if [ $(virsh net-list --all | grep private_network | awk -F ' ' '{print $2}') != 'active' ]; then
    virsh net-start private_network
fi