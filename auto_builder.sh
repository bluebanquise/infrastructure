#!/bin/bash
# Update before executing
set -x
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git -C $SCRIPT_DIR pull
packages/./build.sh $1 $2 $3 $4
