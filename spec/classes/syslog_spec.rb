require 'spec_helper'

describe 'aide::syslog' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|

      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      it { should compile.with_all_deps }
      it { should create_class('aide::syslog') }
      it { should contain_class('rsyslog') }
    end
  end
end
