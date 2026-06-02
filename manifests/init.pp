# Manage the AIDE package and, when explicitly told to, individual settings in
# ``/etc/aide.conf``.
#
# A bare ``include aide`` only installs the ``aide`` package. It does **not**
# overwrite ``/etc/aide.conf``, manage the AIDE database, create directories, or
# schedule anything. Every configuration field is exposed as its own parameter
# that defaults to ``undef``; only the fields you set are managed (as individual
# lines via ``file_line``), leaving the rest of the package-provided
# configuration untouched.
#
# @param dbdir
#   Manage the ``@@define DBDIR`` line (the AIDE database directory).
#
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param logdir
#   Manage the ``@@define LOGDIR`` line (the AIDE log directory).
#
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param database
#   Manage the ``database`` line. This is the full value, e.g.
#   ``'file:@@{DBDIR}/aide.db.gz'``.
#
#   * Only use on **AIDE 0.18 and older**. The ``database`` option was removed
#     in AIDE 0.19 in favor of ``database_in`` (see the ``database_in``
#     parameter).
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param database_in
#   Manage the ``database_in`` line. This is the full value, e.g.
#   ``'file:@@{DBDIR}/aide.db.gz'``.
#
#   * Only use on **AIDE 0.19 and newer**, where it replaces ``database``.
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param database_out
#   Manage the ``database_out`` line. This is the full value, e.g.
#   ``'file:@@{DBDIR}/aide.db.new.gz'``.
#
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param gzip_dbout
#   Manage the ``gzip_dbout`` line (whether to compress the output database).
#
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param verbose
#   Manage the ``verbose`` line (verbosity of the output messages).
#
#   * Only use on **AIDE 0.16 and older**. The ``verbose`` option was removed in
#     AIDE 0.17 in favor of a combination of ``log_level`` and ``report_level``
#     (see those parameters).
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param log_level
#   Manage the ``log_level`` line (the level of log messages).
#
#   * Only use on **AIDE 0.17 and newer**, where (together with ``report_level``)
#     it replaces ``verbose``.
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param report_level
#   Manage the ``report_level`` line (the detail level of the report).
#
#   * Only use on **AIDE 0.17 and newer**, where (together with ``log_level``)
#     it replaces ``verbose``.
#   * Set to ``'absent'`` to remove the line entirely.
#
# @param report_urls
#   Manage a set of ``report_url`` lines. One line is written per array element.
#   Because a report URL is an open-ended string, removals are handled by
#   ``report_urls_purge`` rather than a sentinel value.
#
# @param report_urls_purge
#   A list of ``report_url`` values to ensure are **absent** from the
#   configuration. Each entry is the value only (without the ``report_url=``
#   prefix).
#
# @param aliases
#   Manage AIDE group/macro definitions (e.g. ``'NORMAL = R'``). One line is
#   written per array element, keyed on the group name to the left of the
#   ``=``. Because the right-hand side is an open-ended string, removals are
#   handled by ``aliases_purge`` rather than a sentinel value.
#
# @param aliases_purge
#   A list of group/macro names to ensure are **absent** from the
#   configuration (e.g. ``['NORMAL', 'LSPP']``).
#
# @param ruledir
#   The directory in which `aide::rule` resources write their rule files and
#   which is referenced by the ``@@include`` lines they add.
#
# @param rules
#   A hash of `aide::rule` resources to create.
#
# @param default_rules
#   When set, the curated default ruleset is written via
#   `aide::default_rules`. Accepts a newline-joined string or an array of rule
#   lines. When ``undef`` (the default) no default rules are managed.
#
# @param manage_database
#   When ``true``, manage the AIDE database lifecycle: create the database/log
#   directories, install ``/usr/local/sbin/update_aide``, and initialize/update
#   the database. This is **disruptive** (it builds the AIDE database) and is
#   therefore off by default.
#
# @param database_name
#   The name of the database file within the database directory. Only consumed
#   when ``manage_database`` is ``true``.
#
# @param database_out_name
#   The name of the database out file within the database directory. Only
#   consumed when ``manage_database`` is ``true``.
#
# @param aide_init_timeout
#   Maximum time to wait in seconds for AIDE database initialization. Only
#   consumed when ``manage_database`` is ``true``.
#
# @param enable
#   Whether to enable AIDE to run on a periodic schedule (via
#   `aide::set_schedule`). Enabling this meets CCE-27222-9.
#
# @param minute
#   ``minute`` cron parameter for when the AIDE check is run
#
# @param hour
#   ``hour`` cron parameter for when the AIDE check is run
#
# @param monthday
#   ``monthday`` cron parameter for when the AIDE check is run
#
# @param month
#   ``month`` cron parameter for when the AIDE check is run
#
# @param weekday
#   ``weekday`` cron parameter for when the AIDE check is run
#
# @param cron_method
#   Set to the preferred method for scheduling the job
#
#     * systemd => systemd timer (default)
#     * root    => root's crontab (legacy)
#     * etc     => /etc/crontab (scanner compat)
#
#     * Methods that are not selected will be disabled
#
# @param systemd_calendar
#   An exact systemd calendar string
#
#   * Overrides all other scheduling parameters
#   * Will not be validated
#
# @param cron_command
#   ``command`` cron parameter for when AIDE check is run
#
# @param logrotate
#   Whether to use logrotate. If set to 'true', Hiera can be
#   used to set the variables in aide::logrotate
#
# @param rotate_period
#   The logrotate period at which to rotate the logs.
#
# @param rotate_number
#   The number of log files to preserve on the system.
#
# @param syslog
#   Whether to send the AIDE output to syslog, in addition to the
#   local report file. When ``true`` a ``report_url=syslog:<facility>`` line is
#   managed in ``/etc/aide.conf``. Use Hiera to set the parameters on
#   aide::syslog appropriately if you don't care for the defaults.
#
# @param syslog_facility
#   The syslog facility to use for the AIDE output syslog messages.
#
# @param auditd
#   Whether to add rules for changes to the aide configuration.
#
# @param package_ensure The ensure status of packages to be managed
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide (
  # Individual /etc/aide.conf fields (undef => not managed)
  Optional[Variant[Stdlib::Absolutepath, Enum['absent']]] $dbdir             = undef,
  Optional[Variant[Stdlib::Absolutepath, Enum['absent']]] $logdir            = undef,
  Optional[Variant[Pattern[/\A\w+:/], Enum['absent']]]    $database          = undef,
  Optional[Variant[Pattern[/\A\w+:/], Enum['absent']]]    $database_in       = undef,
  Optional[Variant[Pattern[/\A\w+:/], Enum['absent']]]    $database_out      = undef,
  Optional[Enum['yes', 'no', 'absent']]                   $gzip_dbout        = undef,
  Optional[Variant[Integer[0, 255], Enum['absent']]]      $verbose           = undef,
  Optional[Variant[Aide::LogLevel, Enum['absent']]]       $log_level         = undef,
  Optional[Variant[Aide::ReportLevel, Enum['absent']]]    $report_level      = undef,
  Optional[Array[Pattern[/\A\w+:/]]]                      $report_urls       = undef,
  Array[String[1]]                                        $report_urls_purge = [],
  Optional[Array[Pattern[/\A\S+\s*=.+/]]]                 $aliases           = undef,
  Array[String[1]]                                        $aliases_purge     = [],

  # Rules
  Stdlib::Absolutepath                     $ruledir       = '/etc/aide.conf.d',
  Hash                                     $rules         = {},
  Optional[Variant[Array[String[1]], String]] $default_rules = undef,

  # Database bootstrap (disruptive; off by default)
  Boolean                                  $manage_database   = false,
  String[1]                                $database_name     = 'aide.db.gz',
  String[1]                                $database_out_name = 'aide.db.new.gz',
  Integer                                  $aide_init_timeout = $facts['processors']['count'] ? { 1 => 1200, default => 300 },

  # Scheduling
  Boolean                                  $enable           = false,
  Simplib::Cron::Minute                    $minute           = fqdn_rand(59),
  Simplib::Cron::Hour                      $hour             = 4,
  Simplib::Cron::Monthday                  $monthday         = '*',
  Simplib::Cron::Month                     $month            = '*',
  Simplib::Cron::Weekday                   $weekday          = 0,
  Enum['root', 'etc', 'systemd']           $cron_method      = 'systemd',
  Optional[String[1]]                      $systemd_calendar = undef,
  String[1]                                $cron_command     = '/bin/nice -n 19 /usr/sbin/aide --check',

  # Optional integrations
  Boolean                                  $logrotate       = false,
  Aide::Rotateperiod                       $rotate_period   = 'weekly',
  Integer                                  $rotate_number   = 4,
  Boolean                                  $syslog          = false,
  Aide::SyslogFacility                     $syslog_facility = 'LOG_LOCAL6',
  Boolean                                  $auditd          = false,

  String                                   $package_ensure  = 'installed',
) {
  # These option pairs are mutually exclusive across AIDE versions: only the
  # one matching the installed AIDE version may be set. Fail loudly rather than
  # writing a configuration that the installed AIDE will reject.
  if $verbose =~ NotUndef and ($log_level =~ NotUndef or $report_level =~ NotUndef) {
    fail('aide: `verbose` (AIDE 0.16 and older) cannot be combined with `log_level`/`report_level` (AIDE 0.17 and newer). Set only the option(s) supported by the AIDE version installed on this node.')
  }

  if $database =~ NotUndef and $database_in =~ NotUndef {
    fail('aide: `database` (AIDE 0.18 and older) and `database_in` (AIDE 0.19 and newer) cannot both be set. Set only the one supported by the AIDE version installed on this node.')
  }

  # CCE-27024-9
  package { 'aide':
    ensure => $package_ensure,
  }

  # Only trigger a database rebuild on config changes when we actually manage
  # the database. Otherwise leave the notify unset so there is no dangling
  # reference and no disruptive rebuild on a bare include.
  $_db_notify = $manage_database ? {
    true    => Exec['update_aide_db'],
    default => undef,
  }

  if $default_rules =~ NotUndef {
    include 'aide::default_rules'
  }

  $rules.each |String $key, Hash $attrs| {
    aide::rule { $key:
      * => $attrs,
    }
  }

  if $enable {
    include 'aide::set_schedule'
  }

  if $logrotate {
    include 'aide::logrotate'
  }

  if $syslog {
    include 'aide::syslog'
  }

  if $auditd {
    auditd::rule { 'aide':
      content => '-w /etc/aide.conf -p wa -k CFG_aide',
    }
  }

  # ---------------------------------------------------------------------------
  # Individual /etc/aide.conf field management. Each field is only touched when
  # its parameter is set; an 'absent' sentinel removes the line.
  #
  # Every line is managed with `file_line` and requires `Package['aide']`. The
  # package ships `/etc/aide.conf`, so this both orders the edits after the
  # package install and keeps the catalog noop-safe: on a node where the
  # package (and therefore the file) does not yet exist, a `--noop` run simply
  # reports the pending change instead of failing.
  # ---------------------------------------------------------------------------
  if $dbdir =~ NotUndef {
    $_dbdir_ensure = $dbdir ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf DBDIR':
      ensure            => $_dbdir_ensure,
      path              => '/etc/aide.conf',
      line              => "@@define DBDIR ${dbdir}",
      match             => '^@@define DBDIR\b',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $logdir =~ NotUndef {
    $_logdir_ensure = $logdir ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf LOGDIR':
      ensure            => $_logdir_ensure,
      path              => '/etc/aide.conf',
      line              => "@@define LOGDIR ${logdir}",
      match             => '^@@define LOGDIR\b',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  # `database` (AIDE <= 0.18) and `database_in` (AIDE >= 0.19) are mutually
  # exclusive across AIDE versions; each is managed only when explicitly set.
  if $database =~ NotUndef {
    $_database_ensure = $database ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf database':
      ensure            => $_database_ensure,
      path              => '/etc/aide.conf',
      line              => "database=${database}",
      match             => '^database=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $database_in =~ NotUndef {
    $_database_in_ensure = $database_in ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf database_in':
      ensure            => $_database_in_ensure,
      path              => '/etc/aide.conf',
      line              => "database_in=${database_in}",
      match             => '^database_in=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $database_out =~ NotUndef {
    $_database_out_ensure = $database_out ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf database_out':
      ensure            => $_database_out_ensure,
      path              => '/etc/aide.conf',
      line              => "database_out=${database_out}",
      match             => '^database_out=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $gzip_dbout =~ NotUndef {
    $_gzip_dbout_ensure = $gzip_dbout ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf gzip_dbout':
      ensure            => $_gzip_dbout_ensure,
      path              => '/etc/aide.conf',
      line              => "gzip_dbout=${gzip_dbout}",
      match             => '^gzip_dbout=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  # `verbose` (AIDE <= 0.16) was replaced by `log_level` + `report_level`
  # (AIDE >= 0.17); each is managed only when explicitly set.
  if $verbose =~ NotUndef {
    $_verbose_ensure = $verbose ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf verbose':
      ensure            => $_verbose_ensure,
      path              => '/etc/aide.conf',
      line              => "verbose=${verbose}",
      match             => '^verbose=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $log_level =~ NotUndef {
    $_log_level_ensure = $log_level ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf log_level':
      ensure            => $_log_level_ensure,
      path              => '/etc/aide.conf',
      line              => "log_level=${log_level}",
      match             => '^log_level=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $report_level =~ NotUndef {
    $_report_level_ensure = $report_level ? { 'absent' => 'absent', default => 'present' }
    file_line { 'aide.conf report_level':
      ensure            => $_report_level_ensure,
      path              => '/etc/aide.conf',
      line              => "report_level=${report_level}",
      match             => '^report_level=',
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  if $report_urls =~ NotUndef {
    $report_urls.each |$url| {
      file_line { "aide.conf report_url ${url}":
        path    => '/etc/aide.conf',
        line    => "report_url=${url}",
        require => Package['aide'],
        notify  => $_db_notify,
      }
    }
  }

  $report_urls_purge.each |$url| {
    file_line { "aide.conf report_url ${url} absent":
      ensure  => 'absent',
      path    => '/etc/aide.conf',
      line    => "report_url=${url}",
      require => Package['aide'],
      notify  => $_db_notify,
    }
  }

  if $syslog {
    file_line { 'aide.conf report_url syslog':
      path    => '/etc/aide.conf',
      line    => "report_url=syslog:${syslog_facility}",
      require => Package['aide'],
      notify  => $_db_notify,
    }
  }

  if $aliases =~ NotUndef {
    $aliases.each |$alias| {
      $_alias_name = strip(split($alias, '=')[0])
      file_line { "aide.conf alias ${_alias_name}":
        path    => '/etc/aide.conf',
        line    => $alias,
        match   => "^${_alias_name}\\s*=",
        require => Package['aide'],
        notify  => $_db_notify,
      }
    }
  }

  $aliases_purge.each |$alias_name| {
    file_line { "aide.conf alias ${alias_name} absent":
      ensure            => 'absent',
      path              => '/etc/aide.conf',
      match             => "^${alias_name}\\s*=",
      match_for_absence => true,
      require           => Package['aide'],
      notify            => $_db_notify,
    }
  }

  # ---------------------------------------------------------------------------
  # Database bootstrap. Disruptive: builds the AIDE database. Off by default.
  # ---------------------------------------------------------------------------
  if $manage_database {
    $_dbdir  = $dbdir  =~ Stdlib::Absolutepath ? { true => $dbdir,  default => '/var/lib/aide' }
    $_logdir = $logdir =~ Stdlib::Absolutepath ? { true => $logdir, default => '/var/log/aide' }

    file { $_dbdir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }

    file { $_logdir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }

    $_update_aide_script = @("EOF")
      #!/bin/sh
      /usr/bin/killall -9 aide;
      wait;

      if [ -f ${_dbdir}/${database_name} ]; then
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -u;
      else
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -i;
      fi

      wait;
      cp ${_dbdir}/${database_out_name} ${_dbdir}/${database_name}

      # Need to report aide initialize/update failure. Since aide
      # update returns non-zero error codes even upon success, (return
      # codes 0 - 7), an easy way to determine an aide failure for
      # either initialization or update is to detect a copy failure. The
      # database out will not be created if the initialize/update fails.
      exit $?
      | EOF

    # In update_aide, retain output database for the SCAP Security Guide
    # OVAL check xccdf_org.ssgproject.content_rule_aide_build_database
    file { '/usr/local/sbin/update_aide':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => $_update_aide_script,
    }

    # This is used to automatically update the database when the user
    # changes AIDE configuration.
    exec { 'update_aide_db':
      command     => '/usr/local/sbin/update_aide',
      refreshonly => true,
      require     => [
        Package['aide'],
        File['/usr/local/sbin/update_aide'],
        File[$_dbdir],
        File[$_logdir],
      ],
      timeout     => $aide_init_timeout,
    }

    # CCE-27135-3
    # This makes sure the database is initialized, even if no
    # AIDE configuration has changed.
    exec { 'verify_aide_db_presence':
      command => '/usr/local/sbin/update_aide',
      onlyif  => "/usr/bin/test ! -f ${_dbdir}/${database_name}",
      require => [
        Package['aide'],
        File['/usr/local/sbin/update_aide'],
        File[$_dbdir],
        File[$_logdir],
      ],
      timeout => $aide_init_timeout,
    }
  }
}
