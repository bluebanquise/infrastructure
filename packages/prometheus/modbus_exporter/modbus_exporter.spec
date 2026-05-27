%define version %(echo "%{_software_version}" | sed -e 's/-/\./g')

Name:          prometheus-modbus-exporter
Summary:       Prometheus exporter for Modbus RTU and TCP
Version:       %{version}
Release:       1%{?dist}
License:       apache-2.0
Group:         System Environment/Base
Source0:       https://github.com/RichiH/modbus_exporter/releases/download/v%{_software_version}/%{name}-%{_software_version}.linux-%{_software_architecture}.tar.gz
URL:           https://github.com/RichiH/modbus_exporter
Packager:      Oxedions <oxedions@gmail.com>

BuildRequires: golang>=1.23.0

%description
modbus_exporter for the BlueBanquise stack

The modbus_exporter is a Prometheus exporter that requests data from Modbus 
devices (RTU and TCP) and exposes them for Prometheus scraping.

%prep
mkdir -p %{builddir}
git clone %{url}.git %{builddir}/%{name}
cd %{builddir}/%{name}
git checkout v%{_software_version}

%build
cd %{builddir}/%{name}
go build -o modbus_exporter modbus_exporter.go

%install
#rm -rf %{buildroot}
install -D -m 0755 %{builddir}/%{name}/modbus_exporter %{buildroot}/usr/bin/modbus_exporter

%clean
rm -rf %{buildroot}

%pre

%post

%preun

%postun

%files
%defattr(-,root,root,-)
/usr/bin/modbus_exporter
