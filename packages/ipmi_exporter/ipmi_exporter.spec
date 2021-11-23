Name:     ipmi_exporter
Summary:  ipmi_exporter
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source    https://github.com/prometheus-community/ipmi_exporter/releases/download/v%{_software_version}/ipmi_exporter-%{_software_version}.linux-amd64.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>

Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%define debug_package %{nil}

%description
ipmi_exporter for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prometheus-community/ipmi_exporter/releases/download/v%{_software_version}/ipmi_exporter-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf ipmi_exporter-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a ipmi_exporter-%{_software_version}.linux-amd64/ipmi_exporter $RPM_BUILD_ROOT/usr/local/bin/

# Add services
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system/
cp -a services/ipmi_exporter.service $RPM_BUILD_ROOT/etc/systemd/system/

%pre
/usr/bin/getent group ipmi_exporter || /usr/sbin/groupadd -r ipmi_exporter
/usr/bin/getent passwd ipmi_exporter || /usr/sbin/useradd -r --no-create-home --shell /bin/false ipmi_exporter -g ipmi_exporter

%preun

%post
systemctl daemon-reload
mkdir -p $RPM_BUILD_ROOT/etc/ipmi_exporter

%postun
systemctl daemon-reload
/usr/sbin/userdel ipmi_exporter

%files
%defattr(-,root,root,-)
/usr/local/bin/ipmi_exporter
/etc/systemd/system/ipmi_exporter.service
