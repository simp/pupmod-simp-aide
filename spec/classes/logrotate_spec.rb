require 'spec_helper'

describe 'aide::logrotate' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|

      let(:facts) { facts }
      let(:pre_condition) { 'include "aide"' }

      it { should compile.with_all_deps }
      it { should create_class('aide::logrotate') }
    end
  end
end
