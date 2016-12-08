require 'spec_helper'

describe 'aide::add_rules' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|

      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      let(:title) {'test_rules'}
      let(:params) {{ :rules => 'test_rules' }}

      it { should compile.with_all_deps }
      it { should create_file('/etc/aide.conf.d/test_rules.aide').with_content(/test_rules/) }
    end
  end
end
