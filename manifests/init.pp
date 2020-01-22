# Sets up a functioning AIDE system.
#
# Many parameters were plucked directly from the aide.conf(5)
# man page.
#
# @param dbdir
#   The AIDE database directory, DBDIR.
#
# @param logdir
#   The AIDE log directory, LOGDIR.
#
# @param database_name
#   The name of the database file within DBDIR.
#
# @param database_out_name
#   The name of the database out file within DBDIR.
#
# @param gzip_dbout
#   Whether to compress the output database.
#
# @param verbose
#   The verbosity of the output messages.
#
# @param report_urls
#   An array of report URLs. A syslog report URL will be
#   automatically added to this list when ``syslog`` is
#   set to ``true``.
#
# @param aliases
#   A set of common aliases that may be used within the AIDE
#   configuration file. It is not recommended that these be changed.
#
# @param ruledir
#   The directory to include for all additional rules.
#
# @param rules
#   A hash of `aide::rule` resources to create.
#   In previous versions, this parameter was used to specify an array
#   of rule files to include.  This is now automatic. Passing an
#   array to this parameter is deprecated, does nothing, and may be
#   removed completely in a future release of this module.
#
# @param enable
#   Whether or not to enable AIDE to run on a periodic schedule.
#   Enabling this meets CCE-27222-9.
#
#   This is 'false' by default since AIDE is quite stressful on the
#   system and should be enabled after a good understanding of the
#   performance impact.
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
# @param cron_command
#   ``command`` cron parameter for when AIDE check is run
#
# @param default_rules
#   A set of default rules to include. If this is set, the internal
#   defaults will be overridden.
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
#   local report file. Use Hiera to set the parameters on aide::syslog
#   appropriately if you don't care for the defaults.
#
# @param syslog_facility
#   The syslog facility to use for the AIDE output syslog messages.
#
# @param auditd
#   Whether to add rules for changes to the aide configuration.
#
# @param aide_init_timeout
#   Maximum time to wait in seconds for AIDE database initialization
#
# @param package_ensure The ensure status of packages to be managed
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide (
  Array[String]                     $aliases,          # data in modules
  Variant[Array[String[1]],String]  $default_rules,    #data in modules
  Stdlib::Absolutepath              $dbdir             = '/var/lib/aide',
  Stdlib::Absolutepath              $logdir            = '/var/log/aide',
  String                            $database_name     = 'aide.db.gz',
  String                            $database_out_name = 'aide.db.new.gz',
  Variant[Enum['yes','no'],Boolean] $gzip_dbout        = 'yes',
  Stdlib::Compat::Integer           $verbose           = '5',
  Array[String]                     $report_urls       = [ 'file:@@{LOGDIR}/aide.report'],
  Stdlib::Absolutepath              $ruledir           = '/etc/aide.conf.d',
  Variant[Hash,Array[String]]       $rules             = {},
  Boolean                           $enable            = false,
  Simplib::Cron::Minute             $minute            = 22,
  Simplib::Cron::Hour               $hour              = 4,
  Simplib::Cron::Monthday           $monthday          = '*',
  Simplib::Cron::Month              $month             = '*',
  Simplib::Cron::Weekday            $weekday           = 0,
  String                            $cron_command      = '/bin/nice -n 19 /usr/sbin/aide -C',
  Boolean                           $logrotate         = simplib::lookup('simp_options::logrotate', { 'default_value' => false}),
  Aide::Rotateperiod                $rotate_period     = 'weekly',
  Integer                           $rotate_number     = 4,
  Boolean                           $syslog            = simplib::lookup('simp_options::syslog', { 'default_value' => false }),
  Aide::SyslogFacility              $syslog_facility   = 'LOG_LOCAL6',
  Boolean                           $auditd            = simplib::lookup('simp_options::auditd', { 'default_value' => false }),
  Integer                           $aide_init_timeout = 300,
  String                            $package_ensure    = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  include 'aide::default_rules'

  if $rules =~ Hash {
    $rules.each |String $key, Hash $attrs| {
      aide::rule { $key:
        * => $attrs,
      }
    }
  } else {
    deprecation('aide_rules','Using an Array with $aide::rules is deprecated. The parameter is no longer used to specify rule files')
  }

  if $enable {
    include 'aide::set_schedule'
  }

  if $logrotate {
    include 'aide::logrotate'
  }

  if $syslog {
    include 'aide::syslog'
    $_report_urls = $report_urls << "syslog:${syslog_facility}"
  }
  else {
    $_report_urls = $report_urls
  }

  if $auditd {
    auditd::rule { 'aide':
      content => '-w /etc/aide.conf -p wa -k CFG_aide'
    }
  }

  # CCE-27024-9
  package { 'aide':
    ensure => $package_ensure
  }

  file { $ruledir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    purge   => true,
    recurse => true,
  }

  file { $dbdir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  file { $logdir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  concat { '/etc/aide.conf':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    notify => Exec['update_aide_db'],
  }

  concat::fragment { 'aide.conf':
    target  => '/etc/aide.conf',
    content => template('aide/aide.conf.erb'),
    order   => '001',
  }

  # In update_aide, retain output database for the SCAP Security Guide
  # OVAL check xccdf_org.ssgproject.content_rule_aide_build_database
  file { '/usr/local/sbin/update_aide':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => "#!/bin/sh
      /usr/bin/killall -9 aide;
      wait;

      if [ -f ${dbdir}/${database_name} ]; then
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -u;
      else
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -i;
      fi

      wait;
      cp ${dbdir}/${database_out_name} ${dbdir}/${database_name}

      # Need to report aide initialize/update failure. Since aide
      # update returns non-zero error codes even upon success, (return
      # codes 0 - 7), an easy way to determine an aide failure for
      # either initialization or update is to detect a copy failure. The
      # database out will not be created if the initialize/update fails.
      exit $?"
  }

  # This is used to automatically update the database when the user
  # changes AIDE configuration.
  exec { 'update_aide_db':
    command     => '/usr/local/sbin/update_aide',
    refreshonly => true,
    require     => [
      Package['aide'],
      File['/usr/local/sbin/update_aide'],
      File[$dbdir],
      File[$logdir]
    ],
    timeout     => $aide_init_timeout
  }

  # CCE-27135-3
  # This makes sure the database is initialized, even if no
  # AIDE configuration has changed.
  exec { 'verify_aide_db_presence':
    command => '/usr/local/sbin/update_aide',
    onlyif  => "/usr/bin/test ! -f ${dbdir}/${database_name}",
    require => [
      Package['aide'],
      File['/usr/local/sbin/update_aide'],
      Concat['/etc/aide.conf'],
      Class['aide::default_rules'],
      File[$dbdir],
      File[$logdir]
    ],
    timeout => $aide_init_timeout
  }
}
