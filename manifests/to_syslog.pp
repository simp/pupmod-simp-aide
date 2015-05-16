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
  $logdir = $::aide::logdir,
  $log_severity = 'warning',
  $log_facility = 'local6'
) {
  include '::aide'
  include 'rsyslog'

  rsyslog::add_rule { 'aide_log':
    rule    => "\$InputFileName $logdir/aide.log
      \$InputFileTag tag_aide_log:
      \$InputFileStateFile aide_log
      \$InputFileSeverity $log_severity
      \$InputFileFacility $log_facility
      \$InputRunFileMonitor",
    require => File[$logdir]
  }

  rsyslog::add_rule { 'aide_report':
    rule    => "\$InputFileName $logdir/aide.report
      \$InputFileTag tag_aide_report:
      \$InputFileStateFile aide_report
      \$InputFileSeverity $log_severity
      \$InputFileFacility $log_facility
      \$InputRunFileMonitor",
    require => File[$logdir]
  }
}
