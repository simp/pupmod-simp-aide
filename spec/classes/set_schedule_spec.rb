require 'spec_helper'
require 'fact_groups_helper'

describe 'aide::set_schedule' do

  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) {factgroup}

    context "#{factgroup[:operatingsystem]} #{factgroup[:lsbmajdistrelease]}" do
      it { should create_class('aide::set_schedule') }
      it { should compile.with_all_deps }
      it { should contain_cron('aide_schedule') }
    end
  end
end
