require 'spec_helper'

describe 'aide::rule' do
  context 'supported operating systems' do
    on_supported_os.each_value do |facts|
      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      let(:title) { 'test_rules' }
      let(:params) { { rules: 'test_rules' } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_file('/etc/aide.conf.d/test_rules.aide').with_content(%r{test_rules}) }
    end
  end
end
