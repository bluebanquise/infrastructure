%define is_ubuntu %(grep -i ubuntu /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
%define is_opensuse_leap %(grep -i opensuse-leap /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)

# OpenSuse Leap 15.3:
%if %is_opensuse_leap
  %if %(grep '15.3' /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
     %define dist .osl15.3
  %endif
%endif

# Ubuntu 20.04
%if %is_ubuntu
  %if %(grep '20.04' /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
    %define dist ubuntu.20.04
  %endif
%endif

Name:     ipmi_exporter
Summary:  ipmi_exporter
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/soundcloud/ipmi_exporter/releases/download/v%{_software_version}/ipmi_exporter-%{_software_version}.linux-amd64.tar.gz
URL:      https://github.com/prometheus
Packager: Oxedions <oxedions@gmail.com>

%define debug_package %{nil}

%description
ipmi_exporter for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/soundcloud/ipmi_exporter/releases/download/v%{_software_version}/ipmi_exporter-%{_software_version}.linux-amd64.tar.gz

# Extract
tar xvzf ipmi_exporter-%{_software_version}.linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a ipmi_exporter-%{_software_version}.linux-amd64/ipmi_exporter $RPM_BUILD_ROOT/usr/local/bin/

%pre

%preun

%post

%postun

%files
%defattr(-,root,root,-)
/usr/local/bin/ipmi_exporter
