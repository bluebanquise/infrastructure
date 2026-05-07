Name:           modbus_exporter
Version:        0.4.1
Release:        1
Summary:        Prometheus exporter for Modbus RTU and TCP
License:        MIT
URL:            https://github.com/RichiH/modbus_exporter

Source0:        https://github.com/RichiH/modbus_exporter/releases/download/v%{version}/%{name}-%{version}.linux-amd64.tar.gz
Source1:        modbus_exporter.service
Source2:	sysconfig_modbus_exporter

BuildRequires:  systemd
%{?systemd_requires}
Requires(pre):  shadow-utils

%description
The modbus_exporter is a Prometheus exporter that requests data from Modbus 
devices (RTU and TCP) and exposes them for Prometheus scraping.

%prep
%setup -q -n %{name}

%build
go build -o modbus_exporter modbus_exporter.go

%install
#rm -rf %{buildroot}
install -D -m 0755 modbus_exporter %{buildroot}/usr/bin/modbus_exporter
install -D -m 0644 %{SOURCE1} %{buildroot}/usr/lib/systemd/system/modbus_exporter.service
install -D -m 0644 %{SOURCE2} %{buildroot}/etc/sysconfig/modbus_exporter

%clean
rm -rf %{buildroot}

%pre

%post
%systemd_post modbus_exporter.service

%preun
%systemd_preun modbus_exporter.service

%postun
%systemd_postun_with_restart modbus_exporter.service

%files
%defattr(-,root,root,-)
/usr/bin/modbus_exporter
/usr/lib/systemd/system/modbus_exporter.service
%config(noreplace) /etc/sysconfig/modbus_exporter
