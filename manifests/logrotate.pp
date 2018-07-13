# A class that sets up the logrotate state for aide.
#
# @param logdir Directory containing the logs to be rotated.
#   The logs in that directory are assumed to end with '.log'.
#
# @param rotate_period
#   The logrotate period at which to rotate the logs.
#
# @param rotate_number
#   The number of log files to preserve on the system.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::logrotate (
  Stdlib::Absolutepath $logdir        = $::aide::logdir,
  Aide::Rotateperiod   $rotate_period = $::aide::rotate_period,
  Integer              $rotate_number = $::aide::rotate_number
) {
  assert_private()

  logrotate::rule { 'aide':
    log_files                 => [ "${logdir}/*.log" ],
    missingok                 => true,
    rotate_period             => $rotate_period,
    rotate                    => $rotate_number,
    lastaction_restart_logger => true
  }
}
