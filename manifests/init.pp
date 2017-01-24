# == Class: aide
#
# Use this set up a functioning AIDE system.
#
# Most parameters were plucked directly from the aide.conf(5)
# man page.
#
# == Parameters
#
# [*dbdir*]
#   The AIDE database directory.
#
# [*logdir*]
#   The AIDE log directory.
#
# [*database_name*]
#   The name of the database file within DBDIR.
#
# [*database_out_name*]
#   The name of the database out file within DBDIR.
#
# [*gzip_dbout*]
#   Type: Boolean
#
#   Whether or not to compress the output database.
#
# [*verbose*]
#   Type: Integer
#
#   The verbosity of the output messages.
#
# [*report_urls*]
#   Type: Array
#
#   An array of report URLs.
#
# [*aliases*]
#   Type: Array
#
#   A set of common aliases that may be used within the AIDE
#   configuration file. It is not recommended that these be changed.
#
# [*ruledir*]
#   The directory to include for all additional rules.
#
# [*rules*]
#   Type: Array
#
#   An array of rule files to include.
#
# *The following are not related to aide.conf*
#
# [*enable*]
#   Whether or not to enable AIDE to run on a periodic schedule.
#   Use Hiera to set the parameters on aide::set_schedule
#   appropriately if you don't care for the defaults.
#
#   This is 'false' by default since AIDE is quite stressful on the
#   system and should be enabled after a good understanding of the
#   performance impact.
#
# [*default_rules*]
#   A set of default rules to include. If this is set, the internal
#   defaults will be overridden.
#
# [*logrotate*]
#   Type: Boolean
#
#   Whether or not to use logrotate. If set to 'true', Hiera can be
#   used to set the variables in auditd::logrotate
#
# [*syslog*]
#   Type: Boolean
#
#   Whether or not to send the AIDE output directly to syslog.
#   Use Hiera to set the parameters on aide::syslog appropriately
#   if you don't care for the defaults.
#
# [*auditd*]
#   Type: Boolean
#
#   Whether or not to add rules to the auditd configuration.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class aide (
  Stdlib::Absolutepath              $dbdir             = '/var/lib/aide',
  Stdlib::Absolutepath              $logdir            = '/var/log/aide',
  String                            $database_name     = 'aide.db.gz',
  String                            $database_out_name = 'aide.db.new.gz',
  Variant[Enum['yes','no'],Boolean] $gzip_dbout        = 'yes',
  Stdlib::Compat::Integer           $verbose           = '5',
  Array[String]                     $report_urls       = [ 'file:@@{LOGDIR}/aide.report'],
  Array[String]                     $aliases           = ['R = p+i+l+n+u+g+s+m+c+sha512',
                                                          'L = p+i+l+n+u+g+acl+xattrs',
                                                          '> = p+i+l+n+u+g+S+acl+xattrs',
                                                          'ALLXTRAHASHES = sha1+rmd160+sha256+sha512+tiger',
                                                          'EVERYTHING = R+ALLXTRAHASHES',
                                                          'NORMAL = R',
                                                          'DIR = p+i+n+u+g+acl+xattrs',
                                                          'PERMS = p+i+u+g+acl',
                                                          'LOG = >',
                                                          'LSPP = R',
                                                          'DATAONLY =  p+n+u+g+s+acl+selinux+xattrs+sha256+rmd160+tiger' ],
  Stdlib::Absolutepath              $ruledir           = '/etc/aide.conf.d',
  Array[String]                     $rules             = [ 'default.aide' ],
  Boolean                           $enable            = false,
  String                            $default_rules     = '',
  Boolean                           $logrotate         = simplib::lookup('simp_options::logrotate', { 'default_value' => false}),
  Boolean                           $syslog            = simplib::lookup('simp_options::syslog', { 'default_value'    => false }),
  Boolean                           $auditd            = simplib::lookup('simp_options::auditd', { 'default_value'    => false })
) {

  include '::aide::default_rules'

  if $enable {
    include '::aide::set_schedule'
  }

  if $logrotate {
    include '::aide::logrotate'
  }

  if $syslog {
    include '::aide::syslog'
  }

  if $auditd {
    auditd::rule { 'aide':
      content => '-w /etc/aide.conf -p wa -k CFG_aide'
    }
  }

  # CCE-27024-9
  package { 'aide': ensure => 'latest' }

  file { $ruledir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    purge  => true
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

  file { '/etc/aide.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('aide/aide.conf.erb'),
    notify  => Exec['update_aide_db']
  }

  file { '/usr/local/sbin/update_aide':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => "#!/bin/sh
      killall -9 aide;
      wait;

      if [ -f ${dbdir}/${database_name} ]; then
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -u;
      else
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -i;
      fi

      wait;
      mv ${dbdir}/${database_out_name} ${dbdir}/${database_name}"
  }

  # CCE-27135-3
  exec { 'update_aide_db':
    command     => '/usr/local/sbin/update_aide &',
    refreshonly => true,
    require     => [
      File['/usr/local/sbin/update_aide'],
      File[$dbdir],
      File[$logdir]
    ]
  }

  exec { 'verify_aide_db_presence':
    command => '/usr/local/sbin/update_aide &',
    onlyif  => "/usr/bin/test ! -f ${dbdir}/${database_name}",
    require => [
      File['/usr/local/sbin/update_aide'],
      File[$dbdir],
      File[$logdir]
    ]
  }
}
