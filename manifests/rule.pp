# @summary Add a rule file to the AIDE configuration
#
# This define adds rules to the AIDE configuration. Rules are
# added to `aide::ruledir` unless otherwise specified.
#
# Declaring an `aide::rule` is an explicit caller action, so it writes the rule
# file and adds an `@@include` line to `aide::config_file` (via `file_line`).
# Both require the AIDE package(s) so the configuration the package ships is in
# place first and the catalog stays noop-safe.
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
#   The directory within which all additional rules should be written.
#   Defaults to `aide::ruledir`.
#
# @param order
#   Order of aide rules can be significant. This parameter is retained for
#   backwards compatibility; it no longer affects the generated configuration.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
define aide::rule (
  String               $rules,
  Optional[Stdlib::Absolutepath] $ruledir = undef,
  String                         $order   = '999',
) {
  include 'aide'

  $_ruledir = pick($ruledir, $aide::ruledir)

  ensure_resource('file', $_ruledir, {
    'ensure'  => 'directory',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0700',
    'require' => Package[$aide::package_name],
  })

  file { "${_ruledir}/${name}_simp.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => regsubst($rules, '^\s*', ''),
    require => Package[$aide::package_name],
    notify  => $aide::_db_notify,
  }

  # Match on the rule file name rather than the full ruledir path so that
  # changing `ruledir` updates the existing include line in place instead of
  # leaving a stale one behind. The leading `/` anchor keeps the match scoped to
  # this exact file name (so e.g. rule `foo` does not also match `barfoo`).
  file_line { "aide.conf include ${name}":
    path    => $aide::config_file,
    line    => "@@include ${_ruledir}/${name}_simp.conf",
    match   => "^@@include\\s+\\S*/${name}_simp.conf\$",
    require => [Package[$aide::package_name], File["${_ruledir}/${name}_simp.conf"]].flatten,
    notify  => $aide::_db_notify,
  }

  if $aide::auditd {
    simplib::assert_optional_dependency($module_name, 'simp/auditd')

    # Add auditing rules for the aide configuration.
    auditd::rule { "${name}_simp.conf":
      content => "-w ${_ruledir}/${name}_simp.conf -p wa -k CFG_aide",
    }
  }
}
