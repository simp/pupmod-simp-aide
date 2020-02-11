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
