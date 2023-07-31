# Sets a schedule for AIDE to run a check on your system
#
# @param method
#   How you wish to schedule the run
#
# @param systemd_calendar
#   If `$method` is `systemd`, set this exact calendar string
#
#   This is not verified, use `systemd-analyze calendar` on a modern system to
#   ensure that you have a valid string
#
# @param minute
#   `minute` cron parameter
#
# @param hour
#   `hour` cron parameter
#
# @param monthday
#   `monthday` cron parameter
#
# @param month
#   `month` cron parameter
#
# @param weekday
#   `weekday` cron parameter
#
# @param command
#   `command` cron parameter
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::set_schedule (
  Enum['root', 'etc', 'systemd'] $method           = pick(getvar('aide::cron_method'), 'systemd'),
  Optional[String[1]]            $systemd_calendar = getvar('aide::systemd_calendar'),
  Simplib::Cron::Minute          $minute           = pick(getvar('aide::minute'), fqdn_rand(59)),
  Simplib::Cron::Hour            $hour             = pick(getvar('aide::hour'), 4),
  Simplib::Cron::Monthday        $monthday         = pick(getvar('aide::monthday'), '*'),
  Simplib::Cron::Month           $month            = pick(getvar('aide::month'), '*'),
  Simplib::Cron::Weekday         $weekday          = pick(getvar('aide::weekday'), 0),
  String                         $command          = pick(getvar('aide::cron_command'), '/bin/nice -n 19 /usr/sbin/aide --check')
) {
  assert_private()

  if $systemd_calendar {
    $_systemd_calendar = $systemd_calendar
  }
  else {
    $_systemd_calendar = simplib::cron::to_systemd(
      $minute,
      $hour,
      $month,
      $monthday,
      $weekday
    )
  }

  $_timer = @("EOM")
  [Timer]
  OnCalendar=${_systemd_calendar}
  EOM

  $_service = @("EOM")
  [Service]
  Type=oneshot
  # Exit codes that simply mean that something was changed or updated but that
  # the check ran successfully
  SuccessExitStatus=1 2 3 4 5 6 7
  ExecStart=${command}
  EOM

  systemd::timer { 'puppet_aide.timer':
    timer_content   => $_timer,
    service_content => $_service,
    active          => ($method == 'systemd'),
    enable          => ($method == 'systemd')
  }

  if $method == 'root' {
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
  else {
    cron { 'aide_schedule': ensure => 'absent' }
  }

  # Extract whatever aide command we are running
  if $command =~ /(\/\S+\/aide)/ {
    $_base_command = $1
  }
  else {
    $_base_command = $command
  }

  # Create the augeas regexp match string
  $_regex = "regexp('.*\s?${_base_command}\s?.*')"

  if $method == 'etc' {
    # If only one exists, update it
    augeas { 'aide_schedule':
      context => '/files/etc/crontab',
      changes => [
        "set entry[. = '${command}'][user = 'root']/time/minute '${minute}",
        "set entry[. = '${command}'][user = 'root']/time/hour '${hour}",
        "set entry[. = '${command}'][user = 'root']/time/dayofmonth '${monthday}",
        "set entry[. = '${command}'][user = 'root']/time/month '${month}",
        "set entry[. = '${command}'][user = 'root']/time/dayofweek '${weekday}"
      ],
      onlyif  =>  "match entry[. =~ ${_regex}][user = 'root'] size == 1"
    }

    # If it does not exist, create it
    augeas { 'create_aide_schedule':
      context => '/files/etc/crontab',
      changes => [
        "set entry[last()+1] '${command}'",
        "set entry[last()]/time/minute '${minute}'",
        "set entry[last()]/time/hour '${hour}'",
        "set entry[last()]/time/dayofmonth '${monthday}'",
        "set entry[last()]/time/month '${month}'",
        "set entry[last()]/time/dayofweek '${weekday}'",
        'set entry[last()]/user "root"'
      ],
      onlyif  =>  "match entry[. =~ ${_regex}][user = 'root'] size == 0"
    }

    # If more than one exists, remove all of them and recreate it correctly
    augeas { 'fix_aide_schedule':
      context => '/files/etc/crontab',
      changes => [
        "rm entry[. =~ ${_regex}][user = 'root']",
        "set entry[last()+1] '${command}'",
        "set entry[last()]/time/minute '${minute}'",
        "set entry[last()]/time/hour '${hour}'",
        "set entry[last()]/time/dayofmonth '${monthday}'",
        "set entry[last()]/time/month '${month}'",
        "set entry[last()]/time/dayofweek '${weekday}'",
        'set entry[last()]/user "root"'
      ],
      onlyif  =>  "match entry[. =~ ${_regex}][user = 'root'] size > 1"
    }
  }
  else {
    # Remove all matching schedules
    augeas { 'remove_aide_schedule':
      context => '/files/etc/crontab',
      changes => "rm entry[. =~ ${_regex}][user = 'root']"
    }
  }
}
