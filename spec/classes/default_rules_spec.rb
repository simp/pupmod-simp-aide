require 'spec_helper'

# We have to test aide::default_rules via aide, because aide::default_rules
# is private.  To take advantage of hooks built into puppet-rspec, the class
# described needs to be the class instantiated, i.e., aide.
describe 'aide' do
  on_supported_os.each do |os, os_facts|
    context "supported #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to create_class('aide') }
        it { is_expected.to contain_class('aide::default_rules') }
        it { is_expected.to contain_aide__rule('default').with_ruledir('/etc/aide.conf.d') }
        it {
          expected = <<EOM
/boot   NORMAL
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
/etc/logrotate.simp.d NORMAL
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
!/var/log/and-httpd
EOM
          is_expected.to contain_aide__rule('default').with_rules(expected.strip)
        }
      end

      context 'with custom ruledir' do
        let(:params) {{ :ruledir  => '/etc/aide.d' }}

        it { is_expected.to contain_aide__rule('default').with_ruledir('/etc/aide.d') }
      end

      context 'with custom default rules' do
        let(:custom_rules) { "/bin HIGH\n/sbin HIGH" }
        let(:params) {{ :default_rules => custom_rules }}

        it { is_expected.to contain_aide__rule('default').with_rules(custom_rules) }
      end
    end
  end
end
