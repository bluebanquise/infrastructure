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
%global __requires_exclude_from ^/var/lib/bluebanquise/bluebanquise_venv/.*$
%global __provides_exclude_from ^/var/lib/bluebanquise/bluebanquise_venv/.*$

%global __python_requires %{nil}
%define _buildshell /bin/bash

%description
Bluebanquise stack python virtual environment

%prep
%setup -q

%build

%install
rm -Rf /var/lib/bluebanquise/bluebanquise_venv/
mkdir -p /var/lib/bluebanquise/bluebanquise_venv/
python3 -m venv /var/lib/bluebanquise/bluebanquise_venv/
source /var/lib/bluebanquise/bluebanquise_venv/bin/activate
python3 -m pip install --upgrade pip
pip3 install setuptools setuptools_rust packaging
pip3 install ansible netaddr clustershell jmespath jinja2 flask Flask-RESTful "dask[complete]" waitress paramiko prometheus-client kubernetes

mkdir -p $RPM_BUILD_ROOT/var/lib/bluebanquise/bluebanquise_venv/
cp -a /var/lib/bluebanquise/bluebanquise_venv/* $RPM_BUILD_ROOT/var/lib/bluebanquise/bluebanquise_venv/
rm -Rf /var/lib/bluebanquise/bluebanquise_venv/

%files
%defattr(-,root,root,-)
/var/lib/bluebanquise/bluebanquise_venv/*
