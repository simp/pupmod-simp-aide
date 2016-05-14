require 'spec_helper'
require 'fact_groups_helper'

describe 'aide::default_rules' do
  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) { factgroup }
    let(:pre_condition) { 'include "aide"' }

    it { should create_class('aide::default_rules') }

    context "#{factgroup[:operatingsystem]} #{factgroup[:operatingsystemmajrelease]}" do
      it { should compile.with_all_deps }
      it { should create_file('/etc/aide.conf.d/default.aide').with_content(/\/bin\s+NORMAL/) }
    end
  end
end
