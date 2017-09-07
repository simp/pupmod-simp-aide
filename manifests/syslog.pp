# Persist aide syslog log messages, including report output, to a local
# file.
#
# @param logdir
#   The AIDE log directory.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::syslog (
  Stdlib::Absolutepath $logdir = $::aide::logdir
) {
  assert_private()
  include '::rsyslog'

  rsyslog::rule::local { 'XX_aide':
    rule            => '$programname == \'aide\'',
    target_log_file => "${logdir}/aide.log",
    stop_processing => true
  }
}
