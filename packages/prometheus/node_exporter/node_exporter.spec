Name:     node_exporter
Summary:  node_exporter
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prometheus/node_exporter/releases/download/v%{_software_version}/node_exporter-%{_software_version}.linux-amd64.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>

%define debug_package %{nil}

%description
Node_exporter for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prometheus/node_exporter/releases/download/v%{_software_version}/node_exporter-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf node_exporter-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a node_exporter-%{_software_version}.linux-amd64/node_exporter $RPM_BUILD_ROOT/usr/local/bin/

%pre

%preun

%post

%postun

%files
%defattr(-,root,root,-)
/usr/local/bin/node_exporter
