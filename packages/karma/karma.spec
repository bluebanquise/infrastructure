Name:     karma
Summary:  karma
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prymitive/karma/releases/download/v%{_software_version}/karma.tar.gz
URL:      https://github.com/prymitive
Packager: Oxedions <oxedions@gmail.com>

Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%define debug_package %{nil}

%description
karma for the BlueBanquise stack
%prep

%setup -q

%build

%install

# Download files (binaries)
wget https://github.com/prymitive/karma/releases/download/v%{_software_version}/karma-linux-amd64.tar.gz

# Extract
tar xvzf karma-linux-amd64.tar.gz

# Populate binaries
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
cp -a karma-linux-amd64 $RPM_BUILD_ROOT/usr/local/bin/karma

# Add services
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system/
cp -a services/karma.service $RPM_BUILD_ROOT/etc/systemd/system/

%pre
/usr/bin/getent group karma || /usr/sbin/groupadd -r karma
/usr/bin/getent passwd karma || /usr/sbin/useradd -r --no-create-home --shell /bin/false karma -g karma

%preun

%post
systemctl daemon-reload
mkdir -p $RPM_BUILD_ROOT/etc/karma

%postun
systemctl daemon-reload
/usr/sbin/userdel karma

%files
%defattr(-,root,root,-)
/usr/local/bin/karma
/etc/systemd/system/karma.service
