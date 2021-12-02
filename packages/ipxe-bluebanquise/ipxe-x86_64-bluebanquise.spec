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

%if 0%{?sle_version} 
%define tftp_path /srv/tftpboot/
%define http_path /srv/www/htdocs/
%else
%define tftp_path /var/lib/tftpboot/
%define http_path /var/www/html/
%endif

Name:     ipxe-x86_64-bluebanquise
Summary:  ipxe-x86_64-bluebanquise
Release:  %{_software_release}%{?dist}
Version:  %{_software_version}
License:  MIT and GPL
Group:    System Environment/Base
Source:   https://github.com/oxedions/bluebanquise/ipxe-x86_64-bluebanquise.tar.gz
URL:      https://github.com/oxedions/
Packager: Benoit Leveugle <benoit.leveugle@gmail.com>


%define debug_package %{nil}

%description
License:
 - iPXE source code is under GPL license (http://ipxe.org/)
 - BlueBanquise source code is under MIT license (https://github.com/oxedions/bluebanquise)

Description:
 - iPXE roms/iso/usb_image for the BlueBanquise stack
 - Grub2 auto EFI/shell system image

%prep

%setup -q

%build

%install

working_directory=XXX

# x86_64
mkdir -p $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64
cp $working_directory/build/ipxe/bin/x86_64/grub2_efi_autofind.img $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/grub2_efi_autofind.img
cp $working_directory/build/ipxe/bin/x86_64/grub2_shell.img $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/grub2_shell.img
cp $working_directory/build/ipxe/bin/x86_64/standard_efi.iso $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/standard_efi.iso
#cp $working_directory/build/ipxe/bin/x86_64/standard_pcbios.iso $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/standard_pcbios.iso
#cp $working_directory/build/ipxe/bin/x86_64/standard_pcbios.usb $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/standard_pcbios.usb
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_efi.iso $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_efi.iso
cp $working_directory/build/ipxe/bin/x86_64/noshell_efi.iso $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/noshell_efi.iso
#cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.iso $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.iso
#cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.usb $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.usb


mkdir -p $RPM_BUILD_ROOT/%{tftp_path}/x86_64
cp $working_directory/build/ipxe/bin/x86_64/standard_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/standard_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/standard_undionly.kpxe $RPM_BUILD_ROOT/%{tftp_path}/x86_64/standard_undionly.kpxe
cp $working_directory/build/ipxe/bin/x86_64/standard_snponly_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/standard_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/standard_snp_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/standard_snp_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/dhcpretry_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_undionly.kpxe $RPM_BUILD_ROOT/%{tftp_path}/x86_64/dhcpretry_undionly.kpxe
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_snponly_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/dhcpretry_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_snp_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/dhcpretry_snp_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/noshell_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/noshell_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/noshell_undionly.kpxe $RPM_BUILD_ROOT/%{tftp_path}/x86_64/noshell_undionly.kpxe
cp $working_directory/build/ipxe/bin/x86_64/noshell_snponly_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/noshell_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/noshell_snp_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/x86_64/noshell_snp_ipxe.efi

%files
%defattr(-,root,root,-)
%{http_path}/preboot_execution_environment/bin/x86_64/grub2_efi_autofind.img
%{http_path}/preboot_execution_environment/bin/x86_64/grub2_shell.img
%{http_path}/preboot_execution_environment/bin/x86_64/standard_efi.iso
#%{http_path}/preboot_execution_environment/bin/x86_64/standard_pcbios.iso
#%{http_path}/preboot_execution_environment/bin/x86_64/standard_pcbios.usb
%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_efi.iso
%{http_path}/preboot_execution_environment/bin/x86_64/noshell_efi.iso
#%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.iso
#%{http_path}/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.usb
%{tftp_path}/x86_64/standard_ipxe.efi
%{tftp_path}/x86_64/standard_undionly.kpxe
%{tftp_path}/x86_64/standard_snponly_ipxe.efi
%{tftp_path}/x86_64/standard_snp_ipxe.efi
%{tftp_path}/x86_64/dhcpretry_ipxe.efi
%{tftp_path}/x86_64/dhcpretry_undionly.kpxe
%{tftp_path}/x86_64/dhcpretry_snponly_ipxe.efi
%{tftp_path}/x86_64/dhcpretry_snp_ipxe.efi
%{tftp_path}/x86_64/noshell_ipxe.efi
%{tftp_path}/x86_64/noshell_undionly.kpxe
%{tftp_path}/x86_64/noshell_snponly_ipxe.efi
%{tftp_path}/x86_64/noshell_snp_ipxe.efi


