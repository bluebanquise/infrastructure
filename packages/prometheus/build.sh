
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

set -x

if [ $distribution_version -eq 8 ]; then
  if [ ! -f $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz ]; then
    wget -P $working_directory/sources/ https://github.com/prometheus/client_python/archive/v$prometheus_client_version.tar.gz
    mv $working_directory/sources/v$prometheus_client_version.tar.gz $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz
  fi
fi
rm -Rf $working_directory/build/prometheus
mkdir -p $working_directory/build/prometheus
cd $working_directory/build/prometheus

if [ $distribution_version -eq 8 ]; then
  cp $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz .
  tar xvzf prometheus_client-$prometheus_client_version.tar.gz
  cd client_python-$prometheus_client_version
  python3 setup.py bdist_rpm --spec-only
  cd ..
  mv client_python-$prometheus_client_version prometheus_client-$prometheus_client_version
  tar cvzf prometheus_client-$prometheus_client_version.tar.gz prometheus_client-$prometheus_client_version
  rpmbuild -ta prometheus_client-$prometheus_client_version.tar.gz
fi

if [ $distribution_architecture == 'x86_64' ]; then

    cp -a $root_directory/packages/prometheus/prometheus $working_directory/build/prometheus/prometheus
    mv prometheus prometheus-$prometheus_version
    tar cvzf prometheus-$prometheus_version.linux-amd64.tar.gz prometheus-$prometheus_version
    rpmbuild -ta prometheus-$prometheus_version.linux-amd64.tar.gz --define "_software_version $prometheus_version"

    cp -a $root_directory/packages/prometheus/alertmanager $working_directory/build/prometheus/alertmanager
    mv alertmanager alertmanager-$alertmanager_version
    tar cvzf alertmanager-$alertmanager_version.linux-amd64.tar.gz alertmanager-$alertmanager_version
    rpmbuild -ta alertmanager-$alertmanager_version.linux-amd64.tar.gz --define "_software_version $alertmanager_version"

    cp -a $root_directory/packages/prometheus/node_exporter $working_directory/build/prometheus/node_exporter
    mv node_exporter node_exporter-$node_exporter_version
    tar cvzf node_exporter-$node_exporter_version.linux-amd64.tar.gz node_exporter-$node_exporter_version
    rpmbuild -ta node_exporter-$node_exporter_version.linux-amd64.tar.gz --define "_software_version $node_exporter_version"

    cp -a $root_directory/packages/prometheus/ipmi_exporter $working_directory/build/prometheus/ipmi_exporter
    mv ipmi_exporter ipmi_exporter-$ipmi_exporter_version
    tar cvzf ipmi_exporter-$ipmi_exporter_version.linux-amd64.tar.gz ipmi_exporter-$ipmi_exporter_version
    rpmbuild -ta ipmi_exporter-$ipmi_exporter_version.linux-amd64.tar.gz --define "_software_version $ipmi_exporter_version"

    cp -a $root_directory/packages/prometheus/snmp_exporter $working_directory/build/prometheus/snmp_exporter
    mv snmp_exporter snmp_exporter-$snmp_exporter_version
    tar cvzf snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz snmp_exporter-$snmp_exporter_version
    rpmbuild -ta snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz --define "_software_version $snmp_exporter_version"

    cp -a $root_directory/packages/prometheus/karma $working_directory/build/prometheus/karma
    mv karma karma-$karma_version
    tar cvzf karma-linux-amd64.tar.gz karma-$karma_version
    rpmbuild -ta karma-linux-amd64.tar.gz --define "_software_version $karma_version"

fi

if [ $distribution == "Ubuntu" ]; then
    cd /root
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/prometheus_client-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/prometheus-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/alertmanager-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/node_exporter-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/ipmi_exporter-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/snmp_exporter-*
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/karma-*
    mkdir -p /root/debbuild/DEBS/noarch/
    mv *.deb /root/debbuild/DEBS/noarch/
fi

set +x

