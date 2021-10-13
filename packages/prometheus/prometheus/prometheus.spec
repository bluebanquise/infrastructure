Name:     prometheus
Summary:  prometheus
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prometheus/prometheus/releases/download/v%{_software_version}/prometheus-%{_software_version}.linux-amd64.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>


%define debug_package %{nil}

%description
Prometheus and related tools for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prometheus/prometheus/releases/download/v%{_software_version}/prometheus-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf prometheus-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a prometheus-%{_software_version}.linux-amd64/prometheus $RPM_BUILD_ROOT/usr/local/bin/
cp -a prometheus-%{_software_version}.linux-amd64/promtool $RPM_BUILD_ROOT/usr/local/bin/

%pre

%preun

%post

%postun

%files
%defattr(-,root,root,-)
/usr/local/bin/prometheus
/usr/local/bin/promtool
