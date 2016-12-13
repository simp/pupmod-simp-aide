# == Class aide::logrotate
#
# A class that sets up the logrotate state for aide.
#
# == Parameters
#
# [*rotate_period*]
#   The logrotate period at which to rotate the logs.
#
# [*rotate_number*]
#   The number of log files to preserve on the system.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class aide::logrotate (
  Aide::Rotateperiod      $rotate_period = 'weekly',
  Stdlib::Compat::Integer $rotate_number = '4'
) {
  include '::logrotate'

  logrotate::add { 'aide':
    log_files     => [
      "${::aide::logdir}/*.report",
      "${::aide::logdir}/*.log"
    ],
    missingok     => true,
    rotate_period => $rotate_period,
    rotate        => $rotate_number,
    lastaction    => '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
  }
}
