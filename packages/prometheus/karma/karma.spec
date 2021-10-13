Name:     karma
Summary:  karma
Release:  1%{?dist}
Version:  %{_software_version}
License:  apache-2.0
Group:    System Environment/Base
Source:   https://github.com/prymitive/karma/releases/download/v%{_software_version}/karma-linux-amd64.tar.gz
URL:      https://github.com/prymitive
Packager: Oxedions <oxedions@gmail.com>

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

%pre

%preun

%post

%postun

%files
%defattr(-,root,root,-)
/usr/local/bin/karma
