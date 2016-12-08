require 'spec_helper'

describe 'aide::set_schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|

      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      it { should compile.with_all_deps }
      it { should create_class('aide::set_schedule') }
      it { should contain_cron('aide_schedule') }
    end
  end
end
