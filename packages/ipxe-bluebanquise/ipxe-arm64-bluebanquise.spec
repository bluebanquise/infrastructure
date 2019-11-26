Name:     ipxe-arm64-bluebanquise
Summary:  ipxe-arm64-bluebanquise
Release:  1%{dist}
Version:  XXX
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
mkdir -p $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/arm64
cp $working_directory/build/ipxe/bin/arm64/grub2_efi_autofind.img $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/arm64/grub2_efi_autofind.img
cp $working_directory/build/ipxe/bin/arm64/grub2_shell.img $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/arm64/grub2_shell.img
cp $working_directory/build/ipxe/bin/arm64/standard_efi.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/arm64/standard_efi.iso
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_efi.iso $RPM_BUILD_ROOT/var/www/html/preboot_execution_environment/bin/arm64/dhcpretry_efi.iso


mkdir -p $RPM_BUILD_ROOT/var/lib/tftpboot/arm64
cp $working_directory/build/ipxe/bin/arm64/standard_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/standard_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/standard_snponly_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/standard_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/standard_snp_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/standard_snp_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/dhcpretry_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_snponly_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/dhcpretry_snponly_ipxe.efi
cp $working_directory/build/ipxe/bin/arm64/dhcpretry_snp_ipxe.efi $RPM_BUILD_ROOT/var/lib/tftpboot/arm64/dhcpretry_snp_ipxe.efi

%files
%defattr(-,root,root,-)
/var/www/html/preboot_execution_environment/bin/arm64/grub2_efi_autofind.img
/var/www/html/preboot_execution_environment/bin/arm64/grub2_shell.img
/var/www/html/preboot_execution_environment/bin/arm64/standard_efi.iso
/var/www/html/preboot_execution_environment/bin/arm64/dhcpretry_efi.iso
/var/lib/tftpboot/arm64/standard_ipxe.efi
/var/lib/tftpboot/arm64/standard_snponly_ipxe.efi
/var/lib/tftpboot/arm64/standard_snp_ipxe.efi
/var/lib/tftpboot/arm64/dhcpretry_ipxe.efi
/var/lib/tftpboot/arm64/dhcpretry_snponly_ipxe.efi
/var/lib/tftpboot/arm64/dhcpretry_snp_ipxe.efi

