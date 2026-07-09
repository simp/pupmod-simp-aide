# @summary Add a rule file to the AIDE configuration
#
# This define adds rules to the AIDE configuration. Rules are
# added to /etc/aide.conf.d unless otherwise specified.
#
# Declaring an `aide::rule` is an explicit caller action, so it writes the rule
# file and adds an `@@include` line to `/etc/aide.conf` (via `file_line`). Both
# require `Package['aide']` so the configuration the package ships is in place
# first and the catalog stays noop-safe.
#
# @example Rule to ignore changes to ``/tmp``
#
#   aide::rule { 'tmp':
#     rules => '!/tmp'
#   }
#
# @param name
#
# @param rules
#   The actual string that should be written into the rules file. Leading
#   spaces are stripped so that you can format your manifest in a more readable
#   fashion.
#
# @param ruledir
#   The directory within which all additional rules should be written. This
#   MUST be the same value as that entered in aide::conf if you want the system
#   to work properly.  Default: '/etc/aide.conf.d'
#
# @param order
#   Order of aide rules can be significant. This parameter is retained for
#   backwards compatibility; it no longer affects the generated configuration.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
define aide::rule (
  String               $rules,
  Stdlib::Absolutepath $ruledir = '/etc/aide.conf.d',
  String               $order = '999',
) {
  include 'aide'

  ensure_resource('file', $ruledir, {
    'ensure'  => 'directory',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0700',
    'require' => Package['aide'],
  })

  file { "${ruledir}/${name}_simp.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => regsubst($rules, '^\s*', ''),
    require => Package['aide'],
    notify  => $aide::_db_notify,
  }

  # Match on the rule file name rather than the full `${ruledir}` path so that
  # changing `ruledir` updates the existing include line in place instead of
  # leaving a stale one behind. The leading `/` anchor keeps the match scoped to
  # this exact file name (so e.g. rule `foo` does not also match `barfoo`).
  file_line { "aide.conf include ${name}":
    path    => '/etc/aide.conf',
    line    => "@@include ${ruledir}/${name}_simp.conf",
    match   => "^@@include\\s+\\S*/${name}_simp.conf\$",
    require => [Package['aide'], File["${ruledir}/${name}_simp.conf"]],
    notify  => $aide::_db_notify,
  }

  if $aide::auditd {
    simplib::assert_optional_dependency($module_name, 'simp/auditd')

    # Add auditing rules for the aide configuration.
    auditd::rule { "${name}_simp.conf":
      content => "-w ${ruledir}/${name}_simp.conf -p wa -k CFG_aide",
    }
  }
}
