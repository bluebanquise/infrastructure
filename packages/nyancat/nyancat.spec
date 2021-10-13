# Leap 15.0:
%if 0%{?is_opensuse} && 0%{?sle_version} == 150000
%define dist .osl15.0
%endif

# Leap 15.1:
%if 0%{?is_opensuse} && 0%{?sle_version} == 150100
%define dist .osl15.1
%endif

# Leap 15.2:
%if 0%{?is_opensuse} && 0%{?sle_version} == 150200
%define dist .osl15.2
%endif

# Leap 15.3:
%if 0%{?is_opensuse} && 0%{?sle_version} == 150300
%define dist .osl15.3
%endif

Name:          nyancat
Summary:       nyancat
Version:       %{_software_version}
Release:       1%{dist}
License:       GPL
Group:         System Environment/Libraries
Source:        https://github.com/klange/nyancat.tar.gz
URL:           https://github.com/oxedions/
Packager:      oxedions <oxedions@gmail.com>
%define debug_package %{nil}

%description
License: GPL (https://github.com/klange/nyancat)

Nyancat for fun

%prep
%setup -q

%build

%install
make
mkdir -p $RPM_BUILD_ROOT/usr/bin
cp src/nyancat $RPM_BUILD_ROOT/usr/bin

%files
%defattr(-,root,root,-)
/usr/bin/nyancat
