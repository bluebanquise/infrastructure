       set -x

        if [ ! -f $working_directory/sources/conman-0.3.0.tar.xz ]; then
          wget -P $working_directory/sources/ https://github.com/dun/conman/releases/download/conman-0.3.0/conman-0.3.0.tar.xz
        fi
        rm -Rf $working_directory/build/conman
        mkdir -p $working_directory/build/conman
        cd $working_directory/build/conman
        cp $working_directory/sources/conman-0.3.0.tar.xz $working_directory/build/conman
        tar xJvf conman-0.3.0.tar.xz
        /usr/bin/cp -f $root_directory/packages/conman/* conman-0.3.0/
        tar cvJf conman-0.3.0.tar.xz conman-0.3.0
        rpmbuild -ta conman-0.3.0.tar.xz

        set +x