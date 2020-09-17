Name:     snmp_exporter
Summary:  snmp_exporter
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prometheus/snmp_exporter/releases/download/v%{_software_version}/snmp_exporter.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>

Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%define debug_package %{nil}

%description
snmp_exporter for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prometheus/snmp_exporter/releases/download/v%{_software_version}/snmp_exporter-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf snmp_exporter-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a snmp_exporter-%{_software_version}.linux-amd64/snmp_exporter $RPM_BUILD_ROOT/usr/local/bin/

# Add services
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system/
cp -a services/snmp_exporter.service $RPM_BUILD_ROOT/etc/systemd/system/

%pre
/usr/bin/getent group snmp_exporter || /usr/sbin/groupadd -r snmp_exporter
/usr/bin/getent passwd snmp_exporter || /usr/sbin/useradd -r --no-create-home --shell /bin/false snmp_exporter -g snmp_exporter

%preun

%post
systemctl daemon-reload
mkdir -p $RPM_BUILD_ROOT/etc/snmp_exporter

%postun
systemctl daemon-reload
/usr/sbin/userdel snmp_exporter

%files
%defattr(-,root,root,-)
/usr/local/bin/snmp_exporter
/etc/systemd/system/snmp_exporter.service
