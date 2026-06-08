[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/aide.svg)](https://forge.puppetlabs.com/simp/aide)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/aide.svg)](https://forge.puppetlabs.com/simp/aide)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-aide.svg)](https://travis-ci.org/simp/pupmod-simp-aide)

# pupmod-simp-aide

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Setup](#setup)
  * [What aide affects](#what-aide-affects)
  * [Setup Requirements](#setup-requirements)
* [Usage](#usage)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Description

Sets up a functioning AIDE system.

## Setup

### What aide affects

A bare `include aide` manages **only** the `aide` package. It does not modify
`/etc/aide.conf`, manage the AIDE database, create directories, or schedule
anything.

When you set the corresponding parameters, the module additionally manages:

* Individual settings in `/etc/aide.conf` (one managed line per parameter you
  set, via `file_line` — the rest of the package-provided file is left alone)
* AIDE rules under `/etc/aide.conf.d/` (via `aide::rule` / `default_rules`)
* The AIDE database lifecycle, including `/var/lib/aide/`, `/var/log/aide/` and
  `/usr/local/sbin/update_aide` (only when `manage_database => true`)

### Setup Requirements

This module requires the following:

* [puppetlabs-stdlib](https://forge.puppet.com/puppetlabs/stdlib)
* [simp-auditd](https://forge.puppet.com/simp/auditd)
* [simp-logrotate](https://forge.puppet.com/simp/logrotate)
* [simp-rsyslog](https://forge.puppet.com/simp/rsyslog)
* [simp-simplib](https://forge.puppet.com/simp/simplib)

## Usage

### Bare include (safe, package-only)

```puppet
include aide
```

This installs the `aide` package and changes nothing else. It is safe to apply
on a host that already has AIDE configured, and the catalog is noop-safe even
before the package exists.

### Managing individual `/etc/aide.conf` settings

Each configuration field is its own parameter. Set only the fields you care
about; unset (`undef`) fields are left exactly as the package shipped them.

```puppet
class { 'aide':
  dbdir        => '/var/lib/aide',
  logdir       => '/var/log/aide',
  database     => 'file:@@{DBDIR}/aide.db.gz',
  database_out => 'file:@@{DBDIR}/aide.db.new.gz',
  gzip_dbout   => 'yes',
  verbose      => 5,
  report_urls  => ['file:@@{LOGDIR}/aide.report'],
}
```

#### Version-specific options

Some `aide.conf` options changed across AIDE releases. Pick the parameter that
matches the AIDE version on your nodes:

* **`database` (AIDE 0.18 and older)** vs **`database_in` (AIDE 0.19 and
  newer)** — the `database` option was removed in 0.19 in favor of
  `database_in`. Set only the one appropriate for your version.
* **`verbose` (AIDE 0.16 and older)** vs **`log_level` + `report_level` (AIDE
  0.17 and newer)** — the `verbose` option was removed in 0.17 in favor of the
  `log_level`/`report_level` pair.

```puppet
# AIDE 0.19+ / 0.17+
class { 'aide':
  database_in  => 'file:@@{DBDIR}/aide.db.gz',
  log_level    => 'warning',
  report_level => 'summary',
}
```

#### Removing a setting

Scalar fields accept the sentinel `'absent'` to remove the managed line:

```puppet
class { 'aide':
  gzip_dbout => 'absent',   # removes the gzip_dbout line
}
```

The array fields use sibling purge parameters because their values are
open-ended:

```puppet
class { 'aide':
  report_urls_purge => ['file:@@{LOGDIR}/old.report'],
  aliases_purge     => ['LSPP'],
}
```

### Initializing the AIDE database

Building/refreshing the AIDE database is disruptive, so it is opt-in:

```puppet
class { 'aide':
  manage_database => true,
}
```

### Rules and group/macro definitions (aliases)

Rules and aliases are no longer applied automatically. Opt in by passing them as
parameters (for example via Hiera). Representative values:

```yaml
# Group/macro definitions. On a non-FIPS system you can include sha512:
aide::aliases:
  - 'R = p+i+l+n+u+g+s+m+c+sha512'
  - 'L = p+i+l+n+u+g+acl+xattrs'
  - '> = p+i+l+n+u+g+S+acl+xattrs'
  - 'ALLXTRAHASHES = sha1+sha256+sha512'
  - 'EVERYTHING = R+ALLXTRAHASHES'
  - 'NORMAL = R'
  - 'DIR = p+i+n+u+g+acl+xattrs'
  - 'PERMS = p+i+u+g+acl'
  - 'LOG = >'
  - 'LSPP = R'
  - 'DATAONLY = p+n+u+g+s+acl+selinux+xattrs+sha512'

# On a FIPS-enabled system, only sha1/sha256 are available:
# aide::aliases:
#   - 'R = p+i+l+n+u+g+s+m+c+sha1+sha256'
#   - 'ALLXTRAHASHES = sha1+sha256'
#   - ...
#   - 'DATAONLY = p+n+u+g+s+acl+selinux+xattrs+sha1+sha256'

# A curated default ruleset (abbreviated — see git history for the full set):
aide::default_rules:
  - '/boot   NORMAL'
  - '/bin    NORMAL'
  - '/sbin   NORMAL'
  - '/etc    PERMS'
  - '!/etc/mtab'
  - '/etc/passwd   NORMAL'
  - '/var/log   LOG'
```

## Reference

See [REFERENCE.md](./REFERENCE.md) for the full module reference.

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).
