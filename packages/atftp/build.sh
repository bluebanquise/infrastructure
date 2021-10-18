set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

if [ $distribution_version -eq 7 ]; then
    if [ -f /usr/bin/aclocal-1.16 ]; then
       echo link exist, skipping
    else
        ln -s /usr/bin/aclocal /usr/bin/aclocal-1.16
        ln -s /usr/bin/autoconf /usr/bin/autoconf-1.16
        ln -s /usr/bin/automake /usr/bin/automake-1.16
    fi
fi
rm -Rf $working_directory/build/atftp
mkdir -p $working_directory/build/atftp/

if [ ! -f $working_directory/sources/atftp-0.7.2.tar.gz ]; then
    wget --no-check-certificate -P $working_directory/sources/ https://freefr.dl.sourceforge.net/project/atftp/atftp-0.7.2.tar.gz
fi

cd $working_directory/build/atftp/
cp $working_directory/sources/atftp-0.7.2.tar.gz $working_directory/build/atftp/
tar xvzf atftp-0.7.2.tar.gz
/usr/bin/cp -f $root_directory/packages/atftp/* atftp-0.7.2/
rm -f atftp-0.7.2/redhat/atftp.spec
tar cvzf atftp.tar.gz atftp-0.7.2
rpmbuild -ta atftp.tar.gz

set +x