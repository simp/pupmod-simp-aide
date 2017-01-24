require 'spec_helper'

describe 'aide' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      it { is_expected.to create_class('aide') }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('aide::default_rules') }
        it { is_expected.to_not contain_class('aide::set_schedule') }
        it { is_expected.to_not contain_class('aide::logrotate') }
        it { is_expected.to_not contain_class('aide::syslog') }
        it { is_expected.to_not contain_auditd__rule('aide') }
        it { is_expected.to contain_package('aide') }
      end

      context 'with logrotate, syslog, auditd set to true' do
        let(:params) {{:logrotate => true, :syslog => true, :auditd => true }}
        it { is_expected.to contain_class('aide::logrotate') }
        it { is_expected.to contain_class('aide::syslog') }
        it { is_expected.to contain_class('auditd') }
        it { is_expected.to contain_auditd__rule('aide') }
      end
    end
  end
end
