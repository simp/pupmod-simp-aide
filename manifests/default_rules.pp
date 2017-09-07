# A helper class to keep the main AIDE class relatively readable.
#
# @param default_rules
#   A set of default rules to include. If this is set, the internal
#   defaults will be overridden.
#
# @param ruledir
#   The directory in which the default rules file will be written.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::default_rules (
  String               $default_rules = $::aide::default_rules,
  Stdlib::Absolutepath $ruledir       = $::aide::ruledir
) {

  assert_private()

  if !empty($default_rules) {
    aide::rule { 'default':
      ruledir => $ruledir,
      rules   => $default_rules
    }
  }
  else {
    aide::rule { 'default':
      ruledir => $ruledir,
      rules   => '/boot   NORMAL
/bin    NORMAL
/sbin   NORMAL
/lib    NORMAL
/opt    NORMAL
/usr    NORMAL
/root   NORMAL
!/usr/src
!/usr/tmp
/etc    PERMS
!/etc/mtab
!/etc/.*~
/etc/exports  NORMAL
/etc/fstab    NORMAL
/etc/passwd   NORMAL
/etc/group    NORMAL
/etc/gshadow  NORMAL
/etc/shadow   NORMAL
/etc/security/opasswd   NORMAL
/etc/hosts.allow   NORMAL
/etc/hosts.deny    NORMAL
/etc/sudoers NORMAL
/etc/skel NORMAL
/etc/logrotate.d NORMAL
/etc/resolv.conf DATAONLY
/etc/nscd.conf NORMAL
/etc/securetty NORMAL
/etc/profile NORMAL
/etc/bashrc NORMAL
/etc/bash_completion.d/ NORMAL
/etc/login.defs NORMAL
/etc/zprofile NORMAL
/etc/zshrc NORMAL
/etc/zlogin NORMAL
/etc/zlogout NORMAL
/etc/profile.d/ NORMAL
/etc/X11/ NORMAL
/etc/yum.conf NORMAL
/etc/yumex.conf NORMAL
/etc/yumex.profiles.conf NORMAL
/etc/yum/ NORMAL
/etc/yum.repos.d/ NORMAL
/var/log   LOG
!/var/log/sa
!/var/log/aide/aide.log
!/var/log/aide/aide.report
/etc/audit/ LSPP
/etc/libaudit.conf LSPP
/usr/sbin/stunnel LSPP
/var/spool/at LSPP
/etc/at.allow LSPP
/etc/at.deny LSPP
/etc/cron.allow LSPP
/etc/cron.deny LSPP
/etc/cron.d/ LSPP
/etc/cron.daily/ LSPP
/etc/cron.hourly/ LSPP
/etc/cron.monthly/ LSPP
/etc/cron.weekly/ LSPP
/etc/crontab LSPP
/var/spool/cron/root LSPP
/etc/login.defs LSPP
/etc/securetty LSPP
/var/log/faillog LOG
/var/log/lastlog LOG
/etc/hosts LSPP
/etc/sysconfig LSPP
/etc/inittab LSPP
/etc/grub LSPP
/etc/rc.d LSPP
/etc/ld.so.conf LSPP
/etc/localtime LSPP
/etc/sysctl.conf LSPP
/etc/modprobe.d/00_simp_blacklist.conf LSPP
/etc/pam.d LSPP
/etc/security LSPP
/etc/aliases LSPP
/etc/postfix LSPP
/etc/ssh/sshd_config LSPP
/etc/ssh/ssh_config LSPP
/etc/stunnel LSPP
/etc/vsftpd.ftpusers LSPP
/etc/vsftpd LSPP
/etc/issue LSPP
/etc/issue.net LSPP
/etc/cups LSPP
!/var/log/and-httpd'
    }
  }
}
