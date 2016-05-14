require 'spec_helper'
require 'fact_groups_helper'

describe 'aide::logrotate' do

  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) {factgroup}
    let(:pre_condition) { 'include "aide"' }

    it { should create_class('aide::logrotate') }

    context "#{factgroup[:operatingsystem]} #{factgroup[:operatingsystemmajrelease]}" do
      it { should compile.with_all_deps }
    end
  end
end
