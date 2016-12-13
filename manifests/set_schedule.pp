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
  Stdlib::Compat::Integer                    $minute   = '22',
  Stdlib::Compat::Integer                    $hour     = '4',
  Variant[Enum['*'],Stdlib::Compat::Integer] $monthday = '*',
  Variant[Enum['*'],Stdlib::Compat::Integer] $month    = '*',
  Stdlib::Compat::Integer                    $weekday  = '0'
) {

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
