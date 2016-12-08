require 'spec_helper'

describe 'aide::default_rules' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|

      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      it { should compile.with_all_deps }
      it { should create_class('aide::default_rules') }
      it { should create_file('/etc/aide.conf.d/default.aide').with_content(/\/bin\s+NORMAL/) }
    end
  end
end
