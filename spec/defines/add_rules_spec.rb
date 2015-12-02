require 'spec_helper'
require 'fact_groups_helper'

describe 'aide::add_rules' do

  let(:title) {'test_rules'}
  let(:params) {{ :rules => 'test_rules' }}

  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) {factgroup}

    context "#{factgroup[:operatingsystem]} #{factgroup[:operatingsystemmajrelease]}" do
      it { should compile.with_all_deps }
      it { should create_file('/etc/aide.conf.d/test_rules.aide').with_content(/test_rules/) }
    end
  end
end
