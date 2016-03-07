# == Define: aide::add_rules
#
# This define adds rules to the AIDE configuration. Rules are
# added to /etc/aide.conf.d unless otherwise specified.
#
# == Exampls: _
#
#   aide::add_rules { 'tmp':
#     rules => '!/tmp'
#   }
#
# == Parameters
#
# [*rules*]
#   The actual string that should be written into the rules file. Leading
#   spaces are stripped so that you can format your manifest in a more readable
#   fashion.
#
# [*ruledir*]
#   The directory within which all additional rules should be written. This
#   MUST be the same value as that entered in aide::conf if you want the system
#   to work properly.  Default: '/etc/aide.conf.d'
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define aide::add_rules (
  $rules,
  $ruledir = '/etc/aide.conf.d'
) {
  include '::aide'

  file { "${ruledir}/${name}.aide":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('aide/rules.erb'),
    notify  => Exec['update_aide_db']
  }

  # Add auditing rules for the aide configuration.
  auditd::add_rules { "${name}.aide":
    content => "-w ${ruledir}/${name}.aide -p wa -k CFG_aide"
  }

  validate_absolute_path($ruledir)
}
