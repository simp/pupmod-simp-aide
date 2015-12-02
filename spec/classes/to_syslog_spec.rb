require 'spec_helper'
require 'fact_groups_helper'

describe 'aide::to_syslog' do

  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) {factgroup}

    it { should create_class('aide::to_syslog') }

    context "#{factgroup[:operatingsystem]} #{factgroup[:operatingsystemmajrelease]}" do
      it { should compile.with_all_deps }
      it { should contain_class('rsyslog') }
    end
  end
end
