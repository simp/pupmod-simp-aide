# Sets a schedule for AIDE to run a check on your system via cron.
#
# Enabling this meets CCE-27222-9.
#
# @param minute ``minute`` cron parameter
# @param hour ``hour`` cron parameter
# @param monthday ``monthday`` cron parameter
# @param month ``month`` cron parameter
# @param weekday ``weekday`` cron parameter
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::set_schedule (
  Stdlib::Compat::Integer                    $minute   = $::aide::minute,
  Stdlib::Compat::Integer                    $hour     = $::aide::hour,
  Variant[Enum['*'],Stdlib::Compat::Integer] $monthday = $::aide::monthday,
  Variant[Enum['*'],Stdlib::Compat::Integer] $month    = $::aide::month,
  Stdlib::Compat::Integer                    $weekday  = $::aide::weekday
) {
  assert_private()

  validate_between($minute, 0, 60)
  validate_between($hour, 0, 24)
  validate_between($weekday, 0, 7)

  cron { 'aide_schedule':
    command  => '/bin/nice -n 19 /usr/sbin/aide -C',
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }
}
