[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/aide.svg)](https://forge.puppetlabs.com/simp/vsftpd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/aide.svg)](https://forge.puppetlabs.com/simp/vsftpd)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-aide.svg)](https://travis-ci.org/simp/pupmod-simp-vsftpd)

# pupmod-simp-aide

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with aide](#setup)
    * [What aide affects](#what-aide-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

Sets up a functioning AIDE system.

## Setup

### What aide affects

Manages the following:

* `aide` package
* The following files and directories:
    * `/etc/aide.conf`
    * `/etc/aide.conf.d/`
    * `/var/lib/aide/`
    * `/var/log/aide/`

### Setup Requirements

This module requires the following:

* [puppetlabs-stdlib](https://forge.puppet.com/puppetlabs/stdlib)
* [simp-auditd](https://forge.puppet.com/simp/auditd)
* [simp-logrotate](https://forge.puppet.com/simp/logrotate)
* [simp-rsyslog](https://forge.puppet.com/simp/rsyslog)
* [simp-simplib](https://forge.puppet.com/simp/simplib)

## Usage

    class { 'aide': }

## Reference

### Public Classes

* [aide](https://github.com/simp/pupmod-simp-aide/blob/master/manifests/init.pp)

#### Parameters

* **`dbdir`** (`Stdlib::Absolutepath`) *(defaults to: `'/var/lib/aide'`)*

The AIDE database directory, DBDIR.

* **`logdir`** (`Stdlib::Absolutepath`) *(defaults to: `'/var/log/aide'`)*

The AIDE log directory, LOGDIR.

* **`database\_name`** (`String`) *(defaults to: `'aide.db.gz'`)*

The name of the database file within DBDIR.

* **`database\_out\_name`** (`String`) *(defaults to: `'aide.db.new.gz'`)*

The name of the database out file within DBDIR.

* **`gzip\_dbout`** (`Variant[Enum['yes','no'],Boolean]`) *(defaults to: `'yes'`)*

Whether to compress the output database.

* **`verbose`** (`Stdlib::Compat::Integer`) *(defaults to: `'5'`)*

The verbosity of the output messages.

* **`report\_urls`** (`Array[String]`) *(defaults to: `[ 'file:@@{LOGDIR}/aide.report']`)*

An array of report URLs. A syslog report URL will be automatically added to this list when `syslog` is set to `true`.

* **`aliases`** (`Array[String]`)

A set of common aliases that may be used within the AIDE configuration file. It is not recommended that these be changed.

* **`ruledir`** (`Stdlib::Absolutepath`) *(defaults to: `'/etc/aide.conf.d'`)*

The directory to include for all additional rules.

* **`rules`** (`Array[String]`) *(defaults to: `[ 'default.aide' ]`)*

An array of rule files to include.

* **`enable`** (`Boolean`) *(defaults to: `false`)*

Whether or not to enable AIDE to run on a periodic schedule. Enabling this meets CCE-27222-9.

This is 'false' by default since AIDE is quite stressful on the system and should be enabled after a good understanding of the performance impact.

* **`minute`** (`Stdlib::Compat::Integer`) *(defaults to: `22`)*

`minute` cron parameter for when the AIDE check is run

* **`hour`** (`Stdlib::Compat::Integer`) *(defaults to: `4`)*

`hour` cron parameter for when the AIDE check is run

* **`monthday`** (`Variant[Enum['\*'],Stdlib::Compat::Integer]`) *(defaults to: `'\*'`)*

`monthday` cron parameter for when the AIDE check is run

* **`month`** (`Variant[Enum['\*'],Stdlib::Compat::Integer]`) *(defaults to: `'\*'`)*

`month` cron parameter for when the AIDE check is run

* **`weekday`** (`Stdlib::Compat::Integer`) *(defaults to: `0`)*

`weekday` cron parameter for when the AIDE check is run

* **`default\_rules`** (`String`) *(defaults to: `''`)*

A set of default rules to include. If this is set, the internal defaults will be overridden.

* **`logrotate`** (`Boolean`) *(defaults to: `simplib::lookup('simp_options::logrotate', { 'default_value' => false})`)*

Whether to use logrotate. If set to 'true', Hiera can be used to set the variables in aide::logrotate

* **`rotate\_period`** (`Aide::Rotateperiod`) *(defaults to: `'weekly'`)*

The logrotate period at which to rotate the logs.

* **`rotate\_number`** (`Integer`) *(defaults to: `4`)*

The number of log files to preserve on the system.

* **`syslog`** (`Boolean`) *(defaults to: `simplib::lookup('simp_options::syslog', { 'default_value'    => false })`)*

Whether to send the AIDE output to syslog, in addition to the local report file. Use Hiera to set the parameters on aide::syslog appropriately if you don't care for the defaults.

* **`syslog\_facility`** (`Aide::SyslogFacility`) *(defaults to: `'LOG_LOCAL6'`)*

The syslog facility to use for the AIDE output syslog messages.

* **`auditd`** (`Boolean`) *(defaults to: `simplib::lookup('simp_options::auditd', { 'default_value'    => false })`)*

Whether to add rules for changes to the aide configuration.

* **`aide\_init\_timeout`** (`Integer`) *(defaults to: `300`)*

Maximum time to wait in seconds for AIDE database initialization

### Defined Types

* [aide::rule](https://github.com/simp/pupmod-simp-aide/blob/master/manifests/rule.pp)

This define adds rules to the AIDE configuration. Rules are added to `/etc/aide.conf.d` unless otherwise specified.

Examples:

Rule to ignore changes to `/tmp`

``` example
aide::rule { 'tmp':
  rules => '!/tmp'
}
```

#### Parameters

* **`rules`** (`String`)

The actual string that should be written into the rules file. Leading spaces are stripped so that you can format your manifest in a more readable fashion.

* **`ruledir`** (`Stdlib::Absolutepath`) *(defaults to: `'/etc/aide.conf.d'`)*

The directory within which all additional rules should be written. This MUST be the same value as that entered in aide::conf if you want the system to work properly.

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).
