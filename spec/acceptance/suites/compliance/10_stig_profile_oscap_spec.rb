require 'spec_helper_acceptance'

test_name 'Check SCAP for stig profile'

describe 'run the SSG against the appropriate fixtures for stig aide profile' do
  hosts.each do |host|
    context "on #{host}" do
      let(:os_str) { fact_on(host, 'os.name') + ' ' + fact_on(host, 'os.release.full') }

      let(:ssg_supported) do
        Simp::BeakerHelpers::SSG.new(host)
        true
      rescue
        false
      end

      let(:ssg_runner) do
        Simp::BeakerHelpers::SSG.new(host) if ssg_supported
      end

      let(:ssg_report_data) do
        return nil unless ssg_supported

        profile = 'xccdf_org.ssgproject.content_profile_stig'
        ssg_runner.evaluate(profile)
        # Filter on records containing '_aide_'
        # This isn't perfect, but it should be partially OK
        ssg_runner.process_ssg_results('rule_aide_')
      end

      it 'runs the SSG' do
        pending("SSG support for #{os_str}") unless ssg_supported

        profile = 'xccdf_org.ssgproject.content_profile_stig'

        expect { ssg_runner.evaluate(profile) }.not_to raise_error
      end

      it 'has an SSG report' do
        pending("SSG support for #{os_str}") unless ssg_supported

        expect(ssg_report_data).not_to be_nil

        ssg_runner.write_report(ssg_report_data)
      end

      it 'has run some tests' do
        pending("SSG support for #{os_str}") unless ssg_supported

        expect(ssg_report_data[:failed].count + ssg_report_data[:passed].count).to be > 0
      end

      it 'does not have any failing tests' do
        pending("SSG support for #{os_str}") unless ssg_supported

        if ssg_report_data[:failed].count > 0
          puts ssg_report_data[:report]
        end

        # TODO: See if we can get the SSG to update to a more reasonable set of checks
        pending('SSG Checks Getting Fixed')
        expect(ssg_report_data[:score]).to eq(100)
      end
    end
  end
end
