require 'spec_helper'

describe 'aide::rule' do
  context 'supported operating systems' do
    on_supported_os.each_value do |facts|
      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      let(:title) { 'test_rules' }
      let(:params) { { rules: 'test_rules' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file('/etc/aide.conf.d/test_rules.aide')
          .with_content(%r{test_rules})
          .that_requires('Package[aide]')
      }

      it { is_expected.to contain_file('/etc/aide.conf.d').with_ensure('directory') }

      it {
        is_expected.to contain_file_line('aide.conf include test_rules')
          .with_path('/etc/aide.conf')
          .with_line('@@include /etc/aide.conf.d/test_rules.aide')
          .that_requires('Package[aide]')
      }

      it { is_expected.not_to contain_concat__fragment('aide rule test_rules') }
    end
  end
end
