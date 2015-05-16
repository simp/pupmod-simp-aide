require 'spec_helper'
require 'fact_groups_helper'

describe 'aide' do

  include FactGroups
  FactGroups.factgroups.each do |factgroup|
    let(:facts) { factgroup }

    it { should create_class('aide') }

    context "#{factgroup[:operatingsystem]} #{factgroup[:lsbmajdistrelease]}" do
      it { should compile.with_all_deps }
      it { should contain_class('aide::default_rules') }
      it { should_not contain_class('aide::set_schedule') }
      it { should contain_class('aide::logrotate') }
      it { should contain_class('aide::to_syslog') }
      it { should contain_class('auditd') }
      it { should contain_package('aide') }
    end
  end
end
