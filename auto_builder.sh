#!/bin/bash
# Update before executing
set -x
git pull
packages/./build.sh $1 $2 $3 $4
