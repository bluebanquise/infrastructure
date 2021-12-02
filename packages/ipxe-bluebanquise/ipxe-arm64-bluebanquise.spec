# Leap 15.1:
%if 0%{?is_opensuse} && 0%{?sle_version} == 150100
%define dist .lp151
%endif

%if 0%{?is_opensuse} 
%define tftp_path /srv/tftpboot/
%define http_path /srv/www/htdocs/
%else
%define tftp_path /var/lib/tftpboot/
%define http_path /var/www/html/
%endif

Name:     ipxe-arm64-bluebanquise
Summary:  ipxe-arm64-bluebanquise
Release:  %{_software_release}%{dist}
Version:  %{_software_version}
License:  MIT and GPL
Group:    System Environment/Base
Source:   https://github.com/oxedions/bluebanquise/ipxe-arm64-bluebanquise.tar.gz
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

# arm64
mkdir -p $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/arm64
cp $working_directory/build/ipxe/bin/arm64/grub2_efi_autofind.img $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/arm64/grub2_efi_autofind.img
cp $working_directory/build/ipxe/bin/arm64/grub2_shell.img $RPM_BUILD_ROOT/%{http_path}/preboot_execution_environment/bin/arm64/grub2_shell.img

mkdir -p $RPM_BUILD_ROOT/%{tftp_path}/arm64
cp $working_directory/build/ipxe/bin/arm64/standard_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/standard_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/standard_snponly_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/standard_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/standard_snp_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/standard_snp_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/dhcpretry_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_snponly_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/dhcpretry_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_snp_ipxe.efi $RPM_BUILD_ROOT/%{tftp_path}/arm64/dhcpretry_snp_ipxe.efi

%files
%defattr(-,root,root,-)
%{http_path}/preboot_execution_environment/bin/arm64/grub2_efi_autofind.img
%{http_path}/preboot_execution_environment/bin/arm64/grub2_shell.img
%{tftp_path}/arm64/standard_ipxe.efi
%{tftp_path}/arm64/standard_snponly_ipxe.efi
%{tftp_path}/arm64/standard_snp_ipxe.efi
%{tftp_path}/arm64/dhcpretry_ipxe.efi
%{tftp_path}/arm64/dhcpretry_snponly_ipxe.efi
%{tftp_path}/arm64/dhcpretry_snp_ipxe.efi

