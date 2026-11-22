%define is_ubuntu %(grep -i ubuntu /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
%define is_opensuse_leap %(grep -i opensuse-leap /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)

# SUSE 12.5
%if 0%{?sle_version} == 120500
  %define dist .sl125
%endif
# SUSE 15.1:
%if 0%{?sle_version} == 150100
  %define dist .sl15
%endif
# SUSE 15.2:
%if 0%{?sle_version} == 150200
  %define dist .sl15
%endif
# SUSE 15.3:
%if 0%{?sle_version} == 150300
  %define dist .sl15
%endif
%if 0%{?sle_version} == 150400
  %define dist .sl15
%endif
%if 0%{?sle_version} == 150500
  %define dist .sl15
%endif

# Ubuntu 20.04
%if %is_ubuntu
  %if %(grep '20.04' /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
    %define dist u20
  %endif
  %if %(grep '22.04' /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
    %define dist u22
  %endif
%endif

%if 0%{?sle_version} 
  %define tftp_path /srv/tftpboot/
  %define http_path /srv/www/htdocs/
%else
  %define tftp_path /var/lib/tftpboot/
  %define http_path /var/www/html/
%endif

Name:          memtest86plus-%{_memtest86plus_arch}
Summary:       memtest86plus for %{_memtest86plus_arch} nodes
Version:       %{_software_version}
Release:       1%{?dist}
License:       GPL
Group:         System Environment/Libraries
Source:        https://github.com/memtest86plus/memtest86plus/memtest86plus.tar.gz
URL:           https://github.com/bluebanquise/
Packager:      oxedions <oxedions@gmail.com>
%define debug_package %{nil}

%description
License: GPL-2.0 (https://github.com/memtest86plus/memtest86plus)

Memtest86plus

%prep
# The sources folder keeps the upstream name, not the per-arch package name
%setup -q -n memtest86plus-%{version}

%build

%install
# One folder per target arch, like iPXE (pxe/bin/<arch>/)
mkdir -p $RPM_BUILD_ROOT/%{http_path}/pxe/tools/memtest86plus/%{_memtest86plus_arch}/
cd build/%{_memtest86plus_build_dir}/
make
# The x86_64 image boots both from legacy BIOS and from EFI, the arm64 one from EFI only
%if "%{_memtest86plus_arch}" == "x86_64"
cp mt86plus $RPM_BUILD_ROOT/%{http_path}/pxe/tools/memtest86plus/%{_memtest86plus_arch}/memtest.bin
%endif
cp mt86plus $RPM_BUILD_ROOT/%{http_path}/pxe/tools/memtest86plus/%{_memtest86plus_arch}/memtest.efi

%files
%defattr(-,root,root,-)
%{http_path}/pxe/tools/memtest86plus/%{_memtest86plus_arch}/
