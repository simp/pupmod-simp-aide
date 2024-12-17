require 'spec_helper_acceptance'

test_name 'aide class'

describe 'aide class' do
  let(:manifest) do
    <<-EOS
      include aide
    EOS
  end

  let(:changes_detected) do
    # Both aide --check and aide --update return a non-zero error code
    # when any changes are detected. This is actually a bit mask with
    # bits for new file detections, removed file detections, and changed
    # file detections. Error codes greater than 7 are other errors.
    [1, 2, 3, 4, 5, 6, 7]
  end

  hosts.each do |host|
    context 'with defaults' do
      let(:hieradata) do
        {
          'simp_options::auditd' => false,
       'simp_options::syslog'    => false,
       'simp_options::logrotate' => false,
       'auditd::enable'          => false,
        }
      end

      it 'installs psmisc for killall' do
        # centos/7 box doesn't have psmisc installed by default
        install_package(host, 'psmisc')
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it "'aide' package should be installed" do
        check_for_package(host, 'aide')
      end

      it 'generates the database' do
        on(host, 'ls /var/lib/aide/aide.db.gz')
      end

      it 'retains the output database for SCAP xccdf_org.ssgproject.content_rule_aide_build_database' do
        on(host, 'ls /var/lib/aide/aide.db.new.gz')
      end

      it 'generates an empty or clean report when no problems are found' do
        on(host, '/usr/local/sbin/update_aide')
        on(host, '/usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to match(%r{^(.+NO differences.+)?$})
      end

      it 'generates a valid report when problems are found' do
        on(host, 'touch /etc/yum.conf')
        on(host, '/usr/sbin/aide --check', acceptable_exit_codes: changes_detected)
        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.report")
        on(host, "grep '/etc/.*\.conf' /var/log/aide/aide.report")
      end

      it 'does not generate /var/log/aide/aide.log' do
        on(host, 'ls /var/log/aide/aide.log', acceptable_exit_codes: 2)
      end
    end

    context 'with syslog and logrotate enabled' do
      let(:hieradata) do
        {
          'simp_options::auditd' => false,
       'simp_options::syslog'    => true,
       'simp_options::logrotate' => true,
       'aide::syslog_format'     => true,
       'auditd::enable'          => false,
        }
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
        # rsyslog changes require a second run
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'generates an empty or clean report and log nothing when no problems are found' do
        on(host, '/usr/local/sbin/update_aide')
        on(host, 'logrotate --force /etc/logrotate.simp.d/aide')
        on(host, '/usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to match(%r{^(.+NO differences.+)?$})
        log = on(host, 'cat /var/log/aide/aide.log').stdout
        expect(log).to match(%r{^(.+NO differences.+)?$})
      end

      it 'generates a valid report and log that report when problems are found' do
        on(host, 'touch /etc/yum.conf')
        on(host, '/usr/sbin/aide --check', acceptable_exit_codes: changes_detected)

        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.report")
        on(host, "grep '/etc/.*\.conf' /var/log/aide/aide.report")

        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.log")
        on(host, "grep '/etc/.*\.conf' /var/log/aide/aide.log")
      end
    end
  end
end
