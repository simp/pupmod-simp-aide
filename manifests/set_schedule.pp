# Sets a schedule for AIDE to run a check on your system via cron.
#
# Enabling this meets CCE-27222-9.
#
# @param minute ``minute`` cron parameter
# @param hour ``hour`` cron parameter
# @param monthday ``monthday`` cron parameter
# @param month ``month`` cron parameter
# @param weekday ``weekday`` cron parameter
# @param command ``command`` cron parameter
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::set_schedule (
  Simplib::Cron::Minute   $minute   = $::aide::minute,
  Simplib::Cron::Hour     $hour     = $::aide::hour,
  Simplib::Cron::Monthday $monthday = $::aide::monthday,
  Simplib::Cron::Month    $month    = $::aide::month,
  Simplib::Cron::Weekday  $weekday  = $::aide::weekday,
  String                  $command  = $::aide::cron_command,
) {
  assert_private()

  cron { 'aide_schedule':
    command  => $command,
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }
}
