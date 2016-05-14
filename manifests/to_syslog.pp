# == Class aide::to_syslog
#
# This sends the aide logs to syslog. You must set up the appropriate
# forwarding rules elsewhere if you want to utilize a central site.
# You must also set up a catch for 'local6' to collect this data in
# your site manifest (site.pp). It will be dropped by default. All of
# the SIMP modules will use local6 as the default log level.
#
# == Parameters
#
# [*logdir*]
#   The AIDE log directory. The files 'aide.log' and 'aide.report'
#   will be read from this directory.
#
# [*log_severity*]
#   The syslog log severity at which to log AIDE messages.
#
# [*log_facility*]
#   The syslog log facility at which to log AIDE messages.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class aide::to_syslog (
  # FIXME: add params pattern to aide or make this a private class
  $logdir = defined('$::aide::logdir')? { true => getvar('::aide::logdir'), false => fail("'::aide::logdir' is not defined") },
  $log_severity = 'warning',
  $log_facility = 'local6'
) {
  include '::aide'
  include '::rsyslog'

  rsyslog::rule::other { 'aide_log':
    rule    =>
"input(type=\"imfile\"
  File=\"${logdir}/aide.log\"
  StateFile=\"aide_log\"
  Tag=\"tag_aide_log\"
  Severity=\"${log_severity}\"
  Facility=\"${log_facility}\"
)",
    require => File[$logdir]
  }

  rsyslog::rule::other { 'aide_report':
    rule    =>
"input(type=\"imfile\"
  File=\"${logdir}/aide.report\"
  Tag=\"tag_aide_report\"
  StateFile=\"aide_report\"
  Severity=\"${log_severity}\"
  Facility=\"${log_facility}\"
)",
    require => File[$logdir]
  }
}
