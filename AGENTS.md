# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

`simp-aide` is a SIMP Puppet module that manages AIDE (Advanced Intrusion Detection Environment). It targets EL8/9/10 (RedHat/Alma/Oracle/Rocky) plus CentOS 9/10, on OpenVox 8.

## Ruby / toolchain (read first)

Bundler and the Puppet tooling here **must** run under rvm Ruby 3 (currently `3.4.9`), **not** the system Ruby 4 — system Ruby breaks bundler. New shells load rvm automatically; if a command can't find `bundle`, run `source ~/.rvm/scripts/rvm && rvm use 3.4.9`.

## Commands

```bash
bundle exec rake spec            # Unit tests (runs spec_prep first: clones .fixtures.yml modules)
bundle exec rake spec_prep       # Just set up spec/fixtures/modules symlinks + clones
bundle exec rake spec_clean      # Remove fixtures
bundle exec rubocop              # Ruby style for spec/ files
bundle exec puppet parser validate manifests/*.pp types/*.pp
bundle exec metadata-json-lint metadata.json
bundle exec puppet strings generate --format markdown   # Regenerate REFERENCE.md after any param/doc change
```

Running a single spec file requires fixtures to exist first — `bundle exec rspec spec/...` on its own fails with `Resource type not found: Stdlib::Absolutepath` because it skips `spec_prep`:

```bash
bundle exec rake spec_prep
bundle exec rspec spec/classes/init_spec.rb
```

Known-broken in this environment (do **not** rely on it): `bundle exec rake lint` / `puppet-lint` (4.3.0) crashes on every file (`parse_control_comments … undefined method '[]' for nil`), including unmodified ones. Use `puppet parser validate` for manifest correctness instead. Note `.puppet-lint.rc` disables the 140-char and trailing-comma checks, so long `fail()` strings are acceptable.

Acceptance (beaker) runs against the vagrant nodesets in `spec/acceptance/nodesets/` and is environment-sensitive on this host (system Vagrant must run under system Ruby, and it needs `BEAKER_HYPERVISOR=vagrant_libvirt` for `qemu:///system`). It is currently blocked by host-level vagrant-libvirt issues, not the module.

## Core architecture

**The central invariant: a bare `include aide` is a no-op beyond installing the `aide` package.** Everything else is opt-in. When changing this module, preserve that — `spec/classes/init_spec.rb` asserts the default catalog contains *only* `Package[aide]`.

Config is applied as **individual lines** in the package-shipped `/etc/aide.conf` via stdlib `file_line` — never by templating/overwriting the whole file (the old `concat` + EPP template and the `puppetlabs/concat` dependency were removed for this reason). The pattern, repeated per field in `manifests/init.pp`:

- Each aide.conf setting is its own `Optional[...]` class parameter defaulting to `undef`. When `undef`, **no resource is declared** (the package's line is left untouched).
- Every `file_line` sets `require => Package['aide']` (the package provides the file → ordering + noop-safety on a host without aide), `match_for_absence => true`, and `notify => $_db_notify`.
- `$_db_notify` is `Exec['update_aide_db']` only when `manage_database` is true, else `undef` — so config edits never trigger a DB rebuild on a bare include.

**Deletion conventions** (documented per-parameter):
- Closed/constrainable value spaces use an `'absent'` sentinel folded into the type (e.g. `gzip_dbout => 'absent'`, `Stdlib::Absolutepath` + `Enum['absent']`).
- Open/array value spaces keep the typed param clean and add a sibling purge array: `report_urls` + `report_urls_purge`, `aliases` + `aliases_purge`.

**Version-specific, mutually-exclusive parameters** (validated up front in `init.pp` with `fail()`):
- `verbose` (AIDE ≤ 0.16) vs `log_level` + `report_level` (AIDE ≥ 0.17).
- `database` (AIDE ≤ 0.18) vs `database_in` (AIDE ≥ 0.19).

**Disruptive behavior is gated**, never on by default:
- `manage_database` (default `false`) declares the DB/log directories, `/usr/local/sbin/update_aide`, and the `update_aide_db` / `verify_aide_db_presence` execs that actually build the AIDE database.
- Scheduling (`aide::set_schedule`) is gated by `enable`; `aide::syslog`, `aide::logrotate` by their flags; `auditd` rules by `auditd`.

**Sub-manifests:**
- `manifests/rule.pp` (`aide::rule` define) — writes a rule file under `$ruledir` and adds its `@@include` line to `/etc/aide.conf` via `file_line`. Declaring a rule is an explicit caller action, so it may write config. Creates `$ruledir` via `ensure_resource` (no `purge`).
- `manifests/default_rules.pp` — only included when `default_rules` is set; emits `aide::rule { 'default' }`.
- `types/` — strong type aliases (`Aide::LogLevel`, `Aide::ReportLevel`, `Aide::Rotateperiod`, `Aide::SyslogFacility`). Prefer adding a type alias over inlining `Enum[...]`.

**Hiera / data:** `hiera.yaml` + `data/common.yaml` ship **no auto-applied data** — applying data would violate the no-op-include invariant. The curated default ruleset and the FIPS/non-FIPS `aliases` are documented as copy/paste examples in `README.md` only; operators opt in explicitly.

When adding a new aide.conf field: add the `Optional` param (with a strong type), document it (including a deletion note), add the `file_line` block following the existing pattern, add specs (present + `'absent'`/purge + bad-value rejection), and regenerate `REFERENCE.md`. This is a v9 breaking-change module — do not add backwards-compat shims or `manage_*` toggles beyond the existing gates.
