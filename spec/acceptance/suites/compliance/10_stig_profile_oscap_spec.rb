require 'spec_helper_acceptance'

test_name 'Check SCAP for stig profile'

describe 'run the SSG against the appropriate fixtures for stig aide profile' do

  hosts.each do |host|
    context "on #{host}" do
      before(:all) do
        @os_str = fact_on(host, 'operatingsystem') + ' ' + fact_on(host, 'operatingsystemrelease')

        @ssg_supported = true

        begin
          @ssg = Simp::BeakerHelpers::SSG.new(host)
        rescue
          @ssg_supported = false
        end

        # If we don't do this, the variable gets reset
        @ssg_report = { :data => nil }
      end

      it 'should run the SSG' do
        pending("SSG support for #{@os_str}") unless @ssg_supported

        profile = 'xccdf_org.ssgproject.content_profile_stig'

        @ssg.evaluate(profile)
      end

      it 'should have an SSG report' do
        pending("SSG support for #{@os_str}") unless @ssg_supported

        # Filter on records containing '_aide_'
        # This isn't perfect, but it should be partially OK
        @ssg_report[:data] = @ssg.process_ssg_results('rule_aide_')

        expect(@ssg_report[:data]).to_not be_nil

        @ssg.write_report(@ssg_report[:data])
      end

      it 'should have run some tests' do
        pending("SSG support for #{@os_str}") unless @ssg_supported

        expect(@ssg_report[:data][:failed].count + @ssg_report[:data][:passed].count).to be > 0
      end

      it 'should not have any failing tests' do
        pending("SSG support for #{@os_str}") unless @ssg_supported

        if @ssg_report[:data][:failed].count > 0
          puts @ssg_report[:data][:report]
        end

        # TODO: See if we can get the SSG to update to a more reasonable set of checks
        pending('SSG Checks Getting Fixed')
        expect(@ssg_report[:data][:score]).to eq(100)
      end
    end
  end
end
