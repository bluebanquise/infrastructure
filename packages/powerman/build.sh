        set -x
        
        if [ ! -f $working_directory/sources/powerman-2.3.26.tar.gz ]; then
          wget -P $working_directory/sources/ https://github.com/chaos/powerman/releases/download/2.3.26/powerman-2.3.26.tar.gz
        fi
        rm -Rf $working_directory/build/powerman
        mkdir -p $working_directory/build/powerman
        cd $working_directory/build/powerman
        cp $working_directory/sources/powerman-2.3.26.tar.gz $working_directory/build/powerman
        tar xvzf powerman-2.3.26.tar.gz
        /usr/bin/cp -f $root_directory/powerman/* powerman-2.3.26/
        rm -f powerman-2.3.26/examples/powerman_el72.spec
        tar cvzf powerman-2.3.26.tar.gz powerman-2.3.26
        rpmbuild -ta powerman-2.3.26.tar.gz

        set +x