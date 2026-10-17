require 'spec_helper'

describe 'aide::rule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }
        let(:pre_condition) { 'include "aide"' }
        let(:debian) { facts[:os][:family] == 'Debian' }
        let(:config_file) { debian ? '/etc/aide/aide.conf' : '/etc/aide.conf' }
        let(:ruledir) { debian ? '/etc/aide/aide.conf.d' : '/etc/aide.conf.d' }
        let(:ruledir_attrs) { { owner: 'root', group: 'root', mode: debian ? '0755' : '0700' } }
        let(:title) { 'test_rules' }
        let(:params) { { rules: 'test_rules' } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file("#{ruledir}/test_rules_simp.conf")
            .with_content(%r{test_rules})
            .that_requires('Package[aide]')
        }

        it { is_expected.to contain_file(ruledir).with_ensure('directory').with(ruledir_attrs) }

        it {
          is_expected.to contain_file_line('aide.conf include test_rules')
            .with_path(config_file)
            .with_line("@@include #{ruledir}/test_rules_simp.conf")
            .with_match('^@@include\s+\S*/test_rules_simp.conf$')
            .that_requires('Package[aide]')
        }

        it { is_expected.not_to contain_concat__fragment('aide rule test_rules') }

        if facts[:os][:family] == 'Debian'
          it { is_expected.to contain_file("#{ruledir}/test_rules_simp.conf").that_requires('Package[aide-common]') }
          it { is_expected.to contain_file_line('aide.conf include test_rules').that_requires('Package[aide-common]') }
        end

        context 'with an explicit ruledir' do
          let(:params) { { rules: 'test_rules', ruledir: '/etc/aide.d' } }

          it { is_expected.to contain_file('/etc/aide.d/test_rules_simp.conf') }
          it { is_expected.to contain_file_line('aide.conf include test_rules').with_line('@@include /etc/aide.d/test_rules_simp.conf') }
        end

        context 'with aide::ruledir set' do
          let(:pre_condition) { 'class { "aide": ruledir => "/etc/aide.d" }' }

          it { is_expected.to contain_file('/etc/aide.d/test_rules_simp.conf') }
        end
      end
    end
  end
end
