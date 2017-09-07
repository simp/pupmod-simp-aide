require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'aide' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context 'with FIPS enabled' do
        let(:facts) { 
          facts = os_facts.dup
          facts['fips_enabled'] = true
          facts
        }

        context 'with default parameters' do
          it { is_expected.to create_class('aide') }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('aide::default_rules') }
          it { is_expected.to create_file('/etc/aide.conf.d/default.aide').with_content(/\/bin\s+NORMAL/) }
          it { is_expected.to_not contain_class('aide::set_schedule') }
          it { is_expected.to_not contain_class('aide::logrotate') }
          it { is_expected.to_not contain_class('aide::syslog') }
          it { is_expected.to_not contain_auditd__rule('aide') }
          it { is_expected.to contain_package('aide') }
          it { is_expected.to contain_file('/etc/aide.conf.d').with_ensure('directory') }
          it { is_expected.to contain_file('/var/lib/aide').with_ensure('directory') }
          it { is_expected.to contain_file('/var/log/aide').with_ensure('directory') }
          it { is_expected.to contain_file('/etc/aide.conf').with_content(<<EOM
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide
database=file:@@{DBDIR}/aide.db.gz
database_out=file:@@{DBDIR}/aide.db.new.gz
gzip_dbout=yes
verbose=5
report_url=file:@@{LOGDIR}/aide.report

R = p+i+l+n+u+g+s+m+c+sha1+sha256
L = p+i+l+n+u+g+acl+xattrs
> = p+i+l+n+u+g+S+acl+xattrs
ALLXTRAHASHES = sha1+sha256
EVERYTHING = R+ALLXTRAHASHES
NORMAL = R
DIR = p+i+n+u+g+acl+xattrs
PERMS = p+i+u+g+acl
LOG = >
LSPP = R
DATAONLY = p+n+u+g+s+acl+selinux+xattrs+sha1+sha256

@@include /etc/aide.conf.d/default.aide
EOM
          ) }

          it {
            expected = <<EOM
#!/bin/sh
      /usr/bin/killall -9 aide;
      wait;

      if [ -f /var/lib/aide/aide.db.gz ]; then
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -u;
      else
        /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -i;
      fi

      wait;
      mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

      # Need to report aide initialize/update failure. Since aide
      # update returns non-zero error codes even upon success, (return
      # codes 0 - 7), an easy way to determine an aide failure for
      # either initialization or update is to detect a move failure. The
      # database out will not be created if the initialize/update fails.
      exit $?
EOM
            is_expected.to contain_file('/usr/local/sbin/update_aide').with_content(expected.strip)
          }

          it { is_expected.to contain_exec('update_aide_db').with_command('/usr/local/sbin/update_aide') }
          it { is_expected.to contain_exec('verify_aide_db_presence').with_command('/usr/local/sbin/update_aide') }
        end

        context 'with logrotate, syslog, and auditd set to true' do
          let(:params) {{
            :logrotate     => true,
            :syslog        => true,
            :auditd        => true
          }}

          it{ is_expected.to contain_file('/etc/aide.conf').with_content(
            /report_url=file:@@{LOGDIR}\/aide.report/ )
          }

          it{ is_expected.to contain_file('/etc/aide.conf').with_content(
            /report_url=syslog:LOG_LOCAL6/ )
          }

          it { is_expected.to contain_class('aide::logrotate') }
          it { should create_file('/etc/logrotate.d/aide').with_content(/\/var\/log\/aide\/\*\.log/) }
          it { 
            if ['RedHat','CentOS'].include?(facts[:operatingsystem])
              if facts[:operatingsystemmajrelease].to_s < '7'
                is_expected.to create_file('/etc/logrotate.d/aide').with_content(/#{file_content_6}/)
              else
                is_expected.to create_file('/etc/logrotate.d/aide').with_content(/#{file_content_7}/)
              end
            end
          }

          it { is_expected.to contain_class('aide::syslog') }
          it { is_expected.to contain_class('rsyslog') }
          it { is_expected.to contain_rsyslog__rule__local('XX_aide') }

          it { is_expected.to contain_class('auditd') }
          it { is_expected.to contain_auditd__rule('aide') }
        end

        context 'custom default rules' do
          let(:params) {{
            :default_rules => <<EOM
/bin HIGH
/sbin HIGH
EOM
          }}
          it { is_expected.to create_file('/etc/aide.conf.d/default.aide').with_content(/\/bin\s+HIGH/) }
        end
      end

      context 'with FIPS disabled' do
        let(:facts) { 
          facts = os_facts.dup
          facts['fips_enabled'] = false
          facts
        }

        context 'with default parameters' do
          it { is_expected.to create_class('aide') }
          it { is_expected.to contain_file('/etc/aide.conf').with_content(<<EOM
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide
database=file:@@{DBDIR}/aide.db.gz
database_out=file:@@{DBDIR}/aide.db.new.gz
gzip_dbout=yes
verbose=5
report_url=file:@@{LOGDIR}/aide.report

R = p+i+l+n+u+g+s+m+c+sha512
L = p+i+l+n+u+g+acl+xattrs
> = p+i+l+n+u+g+S+acl+xattrs
ALLXTRAHASHES = sha1+sha256+sha512
EVERYTHING = R+ALLXTRAHASHES
NORMAL = R
DIR = p+i+n+u+g+acl+xattrs
PERMS = p+i+u+g+acl
LOG = >
LSPP = R
DATAONLY = p+n+u+g+s+acl+selinux+xattrs+sha512

@@include /etc/aide.conf.d/default.aide
EOM
          ) }
        end
      end
    end
  end
end
