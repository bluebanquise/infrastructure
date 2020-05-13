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

Name:     ipxe-x86_64-bluebanquise
Summary:  ipxe-x86_64-bluebanquise
Release:  1%{dist}
Version:  XXX
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
mkdir -p $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64
cp $working_directory/build/ipxe/bin/x86_64/grub2_efi_autofind.img $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/grub2_efi_autofind.img
cp $working_directory/build/ipxe/bin/x86_64/grub2_shell.img $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/grub2_shell.img
cp $working_directory/build/ipxe/bin/x86_64/standard_efi.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/standard_efi.iso
cp $working_directory/build/ipxe/bin/x86_64/standard_pcbios.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/standard_pcbios.iso
cp $working_directory/build/ipxe/bin/x86_64/standard_pcbios.usb $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/standard_pcbios.usb
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_efi.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_efi.iso
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.iso
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.usb $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.usb


mkdir -p $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64
cp $working_directory/build/ipxe/bin/x86_64/standard_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/standard_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/standard_undionly.kpxe $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/standard_undionly.kpxe
cp $working_directory/build/ipxe/bin/x86_64/standard_snponly_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/standard_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/standard_snp_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/standard_snp_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/dhcpretry_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_undionly.kpxe $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/dhcpretry_undionly.kpxe
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_snponly_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/dhcpretry_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/x86_64/dhcpretry_snp_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/x86_64/dhcpretry_snp_ipxe.efi

%files
%defattr(-,root,root,-)
/var/www/html/preboot_execution_environment/bin/x86_64/grub2_efi_autofind.img
/var/www/html/preboot_execution_environment/bin/x86_64/grub2_shell.img
/var/www/html/preboot_execution_environment/bin/x86_64/standard_efi.iso
/var/www/html/preboot_execution_environment/bin/x86_64/standard_pcbios.iso
/var/www/html/preboot_execution_environment/bin/x86_64/standard_pcbios.usb
/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_efi.iso
/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.iso
/var/www/html/preboot_execution_environment/bin/x86_64/dhcpretry_pcbios.usb
/var/lib/tftpboot/x86_64/standard_ipxe.efi
/var/lib/tftpboot/x86_64/standard_undionly.kpxe
/var/lib/tftpboot/x86_64/standard_snponly_ipxe.efi
/var/lib/tftpboot/x86_64/standard_snp_ipxe.efi
/var/lib/tftpboot/x86_64/dhcpretry_ipxe.efi
/var/lib/tftpboot/x86_64/dhcpretry_undionly.kpxe
/var/lib/tftpboot/x86_64/dhcpretry_snponly_ipxe.efi
/var/lib/tftpboot/x86_64/dhcpretry_snp_ipxe.efi

