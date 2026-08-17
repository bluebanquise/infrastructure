Name:          bluebanquise-venv
Summary:       bluebanquise-venv
Version:       %{_software_version}
Release:       1%{?dist}
License:       MIT
Group:         System Environment/Libraries
Source:        https://www.bluebanquise.com/bluebanquise-venv.tar.gz
URL:           https://www.bluebanquise.com
Packager:      oxedions <oxedions@gmail.com>
%define debug_package %{nil}
%define __brp_mangle_shebangs /usr/bin/true

# Disable auto dependency/provides scanning for the venv
%global __requires_exclude_from ^/usr/lib/bluebanquise/venv/.*$
%global __provides_exclude_from ^/usr/lib/bluebanquise/venv/.*$

%global __python_requires %{nil}
%define _buildshell /bin/bash

%description
Bluebanquise stack python virtual environment

%prep
%setup -q

%build

%install
rm -Rf /usr/lib/bluebanquise/venv/
mkdir -p /usr/lib/bluebanquise/venv/
python3 -m venv /usr/lib/bluebanquise/venv/
source /usr/lib/bluebanquise/venv/bin/activate
python3 -m pip install --upgrade pip
pip3 install setuptools setuptools_rust packaging
pip3 install ansible netaddr clustershell jmespath jinja2 flask Flask-RESTful "dask[complete]" waitress paramiko prometheus-client kubernetes

mkdir -p $RPM_BUILD_ROOT/usr/lib/bluebanquise/venv/
cp -a /usr/lib/bluebanquise/venv/* $RPM_BUILD_ROOT/usr/lib/bluebanquise/venv/
rm -Rf /usr/lib/bluebanquise/venv/

%files
%defattr(-,root,root,-)
/usr/lib/bluebanquise/venv/*
