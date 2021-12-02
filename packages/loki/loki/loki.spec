%define debug_package %{nil}

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

Name:       loki
Version:    2.4.1
Release:    1%{?dist}
Distribution: %(lsb_release -d -s | sed 's/"//g')
Summary:    Loki
URL:        https://github.com/grafana/loki
Group:      Grafana
License:    Apache License 2.0

Source0: https://github.com/grafana/loki/releases/download/v%{version}/%{name}-linux-amd64.zip
Source1: %{name}.service

%{?systemd_requires}
Requires(pre): shadow-utils
BuildRequires: lsb-release

%description
Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus. It is designed to be very cost effective and easy to operate. It does not index the contents of the logs, but rather a set of labels for each log stream.

%prep
unzip -o %{SOURCE0}

%build
# nothing to do here

# %install
install -D -m 755 %{name}-linux-amd64 %{buildroot}%{_bindir}/%{name}
install -D -m 644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service

%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || \
  useradd -r -g %{name} -d %{_sysconfdir}/%{name} -s /sbin/nologin \
          -c "Loki" %{name}
exit 0

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun %{name}.service

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_unitdir}/%{name}.service

