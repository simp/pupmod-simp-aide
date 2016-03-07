Summary: AIDE Puppet Module
Name: pupmod-aide
Version: 4.1.0
Release: 9
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-auditd >= 4.1.0-3
Requires: pupmod-simplib >= 1.1.0-0
Requires: pupmod-logrotate >= 4.1.0-0
Requires: pupmod-rsyslog >= 5.0.0
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-aide-test
Requires: pupmod-onyxpoint-compliance_markup

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure AIDE for your system.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/aide

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/aide
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/aide

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/aide

%files
%defattr(0640,root,puppet,0750)
%{prefix}/aide

%post
#!/bin/sh

if [ -d %{prefix}/aide/plugins ]; then
  /bin/mv %{prefix}/aide/plugins %{prefix}/aide/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Thu Mar 10 2016 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-10
- Updated for Puppet 4 compatibility

* Wed Feb 10 2016 Ralph Wright <ralph.wright@onypoint.com> - 4.1.0-9
- Added compliance function support

* Mon Nov 09 2015 Chris Tessmer <chris.tessmer@onypoint.com> - 4.1.0-8
- migration to simplib and simpcat (lib/ only)

* Fri Jul 31 2015 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-7
- Updated logging configuration to work with new rsyslog module.

* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-6
- Changed calls directly to /etc/init.d/rsyslog to '/sbin/service rsyslog' so
  that both RHEL6 and RHEL7 are properly supported.
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-5
- Changed puppet-server requirement to puppet

* Tue Jul 08 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Modified the grub regex to work with grub2.

* Sun Jun 22 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-3
- Removed MD5 file checksums for FIPS compliance.

* Mon Apr 07 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-2
- Added validation for instance variables.
- Added spec tests.

* Sat Feb 15 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-1
- Converted all boolean strings to native booleans.

* Fri Nov 08 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Rearchitected the entire module to eliminate all singleton defines
  and work better with a Hiera-based architecture.

* Thu Oct 03 2013 - Nick Markowski <nmarkowski@keywcorp.com> - 4.0.0-8
- Updated template to reference instance variables with @

* Tue Jan 8 2013 Maintenance
4.0.0-7
- Created a test to install the aide module and make sure that a modified file will be detected.

* Thu Dec 13 2012 Maintenance
4.0.0-6
- Updated to require pupmod-common >= 2.1.1-2 so that upgrading an old
  system works properly.

* Tue Sep 18 2012 Maintenance
4.0.0-5
- Updated all references of /etc/modprobe.conf to /etc/modprobe.d/00_simp_blacklist.conf
  as modprobe.conf is now deprecated.

* Wed Apr 11 2012 Maintenance
4.0.0-4
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
4.0.0-3
- Improved test stubs.

* Tue Jan 31 2012 Maintenance
4.0.0-2
- Added test stubs.

* Mon Dec 26 2011 Maintenance
4.0.0-1
- Updated to build without building the filelist separately.

* Mon Nov 07 2011 Maintenance
4.0.0-0
- Fixed call to rsyslog restart for RHEL6.

* Fri Nov 04 2011 Maintenance
2.0.0-2
- Fixed a bug in the logrotate call for aide.

* Fri Jul 15 2011 Maintenance
2.0.0-1
- Updated to use logrotate by default for AIDE log files.

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Maintenance - 1-2
- Converting all spec files to check for directories prior to copy.

* Wed Jul 21 2010 Maintenance
1.0-1
- More refactoring.
- Updates to increase configurability.

* Wed May 19 2010 Maintenance
1.0-0
- Code refactor.
