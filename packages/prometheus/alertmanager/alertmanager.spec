Name:     alertmanager
Summary:  alertmanager
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prometheus/alertmanager/releases/download/v%{_software_version}/alertmanager-%{_software_version}.linux-amd64.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>

%define debug_package %{nil}

%description
Alertmanager and related tools for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prometheus/alertmanager/releases/download/v%{_software_version}/alertmanager-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf alertmanager-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a alertmanager-%{_software_version}.linux-amd64/alertmanager $RPM_BUILD_ROOT/usr/local/bin/
cp -a alertmanager-%{_software_version}.linux-amd64/amtool $RPM_BUILD_ROOT/usr/local/bin/

%preun

%files
%defattr(-,root,root,-)
/usr/local/bin/alertmanager
/usr/local/bin/amtool
