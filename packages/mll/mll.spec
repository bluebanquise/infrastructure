Name:     mll
Summary:  mll
Release:  1%{?dist}
Version:  %{_software_version}
License:  MIT
Group:    System Environment/Base
URL:      https://github.com/ivandavidov/minimal
Source:   https://bluebanquise.com/sources/mll-%{_software_version}.tar.gz
Packager: Benoit Leveugle <benoit.leveugle@gmail.com>

%define debug_package %{nil}

%description
MLL build for BlueBanquise PXE

%prep

%setup -q

%post
restorecon -Rv /var/www/html/preboot_execution_environment/MLL

%build

%install
# Populate binaries
mkdir -p $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/MLL/%{_architecture}/
cp kernel.xz rootfs.xz $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/MLL/%{_architecture}/

%files
%defattr(-,root,root,-)
/var/www/html/preboot_execution_environment/MLL/%{_architecture}/*

%changelog

* Wed Aug 11 2021 Benoit Leveugle <benoit.leveugle@gmail.com>
- Create
