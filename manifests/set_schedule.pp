# == Class: aide::set_schedule
#
# Sets a schedule for AIDE to run a check on your system via cron.
#
# Enabling this meets CCE-27222-9.
#
# == Parameters
#
# The parameters for this are simply the cron parameters.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class aide::set_schedule (
  $minute = '22',
  $hour = '4',
  $monthday = '*',
  $month = '*',
  $weekday = '0'
) {
  cron { 'aide_schedule':
    command  => '/bin/nice -n 19 /usr/sbin/aide -C',
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }

  validate_between($minute, 0, 60)
  validate_between($hour, 0, 24)
  validate_between($weekday, 0, 7)
}
