# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Overview

`pupmod-simp-aide` (Puppet Forge: `simp/aide`) is a SIMP Puppet module that configures a
functioning AIDE (Advanced Intrusion Detection Environment) file-integrity system on
RHEL-family hosts (RHEL/CentOS/Oracle/Rocky/Alma 8–10). It manages the `aide` package,
`/etc/aide.conf`, the rule directory, the database/log directories, and the scheduled
integrity check.

## Commands

Dependencies are installed via Bundler (`bundle install`); always run rake tasks through
`bundle exec`.

- **Run all unit tests + lint:** `bundle exec rake test` (alias for the default validation suite)
- **Run unit tests only:** `bundle exec rake spec`
- **Run a single spec file:** `bundle exec rspec spec/classes/init_spec.rb`
- **Run a single example by line:** `bundle exec rspec spec/classes/init_spec.rb:42`
- **Lint Puppet code:** `bundle exec rake lint` (puppet-lint, config in `.puppet-lint.rc`)
- **Validate syntax/metadata:** `bundle exec rake validate`
- **Ruby style:** `bundle exec rake rubocop` (config in `.rubocop.yml`)
- **List all tasks:** `bundle exec rake -T`
- **Regenerate REFERENCE.md** from puppet-strings docs: `bundle exec rake strings:generate:reference`

`bundle exec rake spec` automatically clones fixture modules (see `.fixtures.yml`) into
`spec/fixtures/modules/`. Run `bundle exec rake spec_clean` to clear them.

### Acceptance tests

Beaker-based, in `spec/acceptance/suites/`. They require Docker/VM nodesets from
`spec/acceptance/nodesets/`. Select the platform with `BEAKER_set`, e.g.:

```
BEAKER_set=docker_rhel9 bundle exec rake beaker:suites
```

## Architecture

The module entrypoint is `manifests/init.pp` (`class aide`). It is parameter-driven with
defaults supplied via Hiera (`data/common.yaml`, mapped through `hiera.yaml`). Key flow:

- **`aide::default_rules`** — always included; emits the baseline AIDE rule set defined in
  `data/common.yaml` (`aide::default_rules`, deep-merged with `--` knockout prefix so
  consumers can extend or remove individual rules via Hiera).
- **`/etc/aide.conf`** is assembled with `concat`. The header fragment is rendered from
  `templates/aide.conf.epp`; each `aide::rule` adds an `@@include` fragment whose `order`
  controls placement (rule order is significant to AIDE).
- **`aide::rule`** (`manifests/rule.pp`) — defined type writing individual `*.aide` rule
  files into `$ruledir` (`/etc/aide.conf.d`). The `rules` hash passed to `class aide` is
  iterated to create these. Passing an Array to `aide::rules` is deprecated and ignored.
- **Database lifecycle** — `init.pp` writes `/usr/local/sbin/update_aide` and drives it via
  two execs: `update_aide_db` (refresh-only, triggered by config changes) and
  `verify_aide_db_presence` (initializes the DB if absent, satisfying CCE-27135-3). The DB
  out file is intentionally retained for SCAP/OVAL `aide_build_database` checks.
- **Scheduling** — `aide::set_schedule` (included only when `enable => true`) supports three
  mutually exclusive `cron_method` values: `systemd` (default, via `systemd::timer`), `root`
  (root crontab), and `etc` (`/etc/crontab` managed via augeas). Unselected methods are
  actively disabled/removed. `simplib::cron::to_systemd` converts cron fields to a systemd
  calendar string unless `systemd_calendar` is set explicitly.
- **Optional integrations** — `aide::logrotate`, `aide::syslog`, and auditd rules are gated
  by the `logrotate`, `syslog`, and `auditd` booleans. `auditd` requires the optional
  `simp/auditd` dependency (asserted at runtime via `simplib::assert_optional_dependency`).

Custom Puppet types live in `types/` (`Aide::Rotateperiod`, `Aide::SyslogFacility`).

## Conventions

- This is a `puppetsync`-managed SIMP baseline. Files with a "maintained with puppetsync"
  header (`Gemfile`, `.puppet-lint.rc`, `.rubocop.yml`, etc.) are overwritten by baseline
  syncs — avoid local edits to them.
- Defaults belong in `data/common.yaml`, not hardcoded in manifests, where practical.
- `aide::aliases` and `aide::default_rules` are required class parameters (no manifest
  default) — they are supplied by Hiera and validated as deps when reasoning about the catalog.
- Issues are tracked in SIMP JIRA (https://simp-project.atlassian.net), not GitHub Issues.
