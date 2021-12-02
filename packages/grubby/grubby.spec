Name:     grubby
Summary:  grubby
Release:  1%{?dist}
Version:  %{_software_version}
License:  GPL-2.0
Group:    System Environment/Base
Source:   https://github.com/rhboot/grubby/archive/refs/tags/grubby-%{_software_version}.tar.gz
URL:      https://github.com/rhboot/grubby
Packager: Oxedions <oxedions@gmail.com>

%define debug_package %{nil}

%description
grubby for the BlueBanquise stack
%prep

%setup -q

%build

%install

mkdir -p $RPM_BUILD_ROOT/usr/bin/
cp -a grubby $RPM_BUILD_ROOT/usr/bin/

%files
%defattr(-,root,root,-)
/usr/bin/grubby
