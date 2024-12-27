set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

#if [ $distribution_version -eq 7 ]; then
#    if [ -f /usr/bin/aclocal-1.16 ]; then
#       echo link exist, skipping
#    else
if [[ ! -f /usr/bin/aclocal-1.16 ]]; then ln -s /usr/bin/aclocal /usr/bin/aclocal-1.16; fi
if [[ ! -f /usr/bin/autoconf-1.16 ]]; then ln -s /usr/bin/autoconf /usr/bin/autoconf-1.16; fi
if [[ ! -f /usr/bin/automake-1.16 ]]; then ln -s /usr/bin/automake /usr/bin/automake-1.16; fi

        #ln -s /usr/bin/autoconf /usr/bin/autoconf-1.16
        #ln -s /usr/bin/automake /usr/bin/automake-1.16
#    fi
#fi

rm -Rf $working_directory/build/atftp
mkdir -p $working_directory/build/atftp/

if [ ! -f $working_directory/sources/atftp-$atftp_version.tar.gz ]; then
    wget --no-check-certificate -P $working_directory/sources/ https://freefr.dl.sourceforge.net/project/atftp/atftp-$atftp_version.tar.gz
fi

cd $working_directory/build/atftp/
cp $working_directory/sources/atftp-$atftp_version.tar.gz $working_directory/build/atftp/
tar xvzf atftp-$atftp_version.tar.gz
/usr/bin/cp -f $root_directory/atftp/* atftp-$atftp_version/
rm -f atftp-$atftp_version/redhat/atftp.spec
mv atftp-$atftp_version bluebanquise-atftp-$atftp_version
tar cvzf atftp.tar.gz bluebanquise-atftp-$atftp_version
rpmbuild -ta atftp.tar.gz --define "_software_version $atftp_version" --define "_lto_cflags %{nil}"

set +x
