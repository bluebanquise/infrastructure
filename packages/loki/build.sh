#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR

for p in loki promtail; do
	cd $p
	rpmbuild --define "%_sourcedir %(echo $PWD)"  --undefine=_disable_source_fetch -bb $p.spec
	cd ..
done

