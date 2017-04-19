require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'aide::logrotate' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on os #{os}" do
        let(:facts) { facts }
        let(:pre_condition) { 'include "aide"' }

        context 'with default parameters' do
          it { should compile.with_all_deps }
          it { should create_class('aide::logrotate') }
          if ['RedHat','CentOS'].include?(facts[:operatingsystem])
            if facts[:operatingsystemmajrelease].to_s < '7'
              it { should create_file('/etc/logrotate.d/aide').with_content(/#{file_content_6}/)}
            else
              it { should create_file('/etc/logrotate.d/aide').with_content(/#{file_content_7}/)}
            end
          end
        end
      end
    end
  end
end
