#!/bin/sh
# Wait until SSH is available on a remote host.
# Usage: waitforssh.sh user@host
echo "Waiting for SSH on $1 ..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1" echo hello
while test $? -gt 0; do
    sleep 5
    echo "  retrying $1 ..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1" echo hello
done
echo "SSH ready on $1"
