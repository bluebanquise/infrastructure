%define is_ubuntu %(grep -i ubuntu /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)
%define is_debian %(grep -i debian /etc/os-release >/dev/null; if test $? -gt 0; then echo 0; else echo 1; fi)


Name: bluebanquise-atftp
Summary: Advanced Trivial File Transfer Protocol (ATFTP) - TFTP server
Group: System Environment/Daemons
Version: %{_software_version}
Release: 1
License: GPL
Vendor: Linux Networx Inc.
Source: https://freefr.dl.sourceforge.net/project/atftp/atftp.tar.gz
Buildroot: /var/tmp/atftp-buildroot
Packager: Benoit Leveugle <benoit.leveugle@gmail.com>

Obsoletes: atftp

%description
Multithreaded TFTP server implementing all options (option extension and
multicast) as specified in RFC1350, RFC2090, RFC2347, RFC2348 and RFC2349.
Atftpd also support multicast protocol knowed as mtftp, defined in the PXE
specification. The server supports being started from inetd(8) as well as
a deamon using init scripts.


%package client
Summary: Advanced Trivial File Transfer Protocol (ATFTP) - TFTP client
Group: Applications/Internet


%description client
Advanced Trivial File Transfer Protocol client program for requesting
files using the TFTP protocol.


%prep
%setup


%build
%configure
make


%install
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != '/' ] && rm -rf $RPM_BUILD_ROOT
%makeinstall
mkdir -p ${RPM_BUILD_ROOT}/usr/lib/systemd/system/
cp atftpd.service ${RPM_BUILD_ROOT}/usr/lib/systemd/system/atftpd.service
chmod 644 ${RPM_BUILD_ROOT}/usr/lib/systemd/system/atftpd.service


%files
%if %is_debian
%else
%{_mandir}/man8/atftpd.8.gz
%{_mandir}/man8/in.tftpd.8.gz
%endif
%{_sbindir}/atftpd
%{_sbindir}/in.tftpd
/usr/lib/systemd/system/atftpd.service


%files client
%if %is_debian
%else
%{_mandir}/man1/atftp.1.gz
%endif
%{_bindir}/atftp


%preun


%post
adduser --system -d /var/lib/tftpboot tftp || true
usermod -a -G tftp apache || true

%clean
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != '/' ] && rm -rf $RPM_BUILD_ROOT


%changelog
* Wed Dec 01 2021 Benoit Leveugle <benoit.leveugle@gmail.com>
- Adapt to bluebanquise
* Tue Jan 07 2003 Thayne Harbaugh <thayne@plug.org>
- put client in sub-rpm
