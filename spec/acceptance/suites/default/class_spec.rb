require 'spec_helper_acceptance'

test_name 'aide class'

describe 'aide class' do
  let(:manifest) {
    <<-EOS
      class { 'aide': }
    EOS
  }

  let(:changes_detected) {
    # Both aide --check and aide --update return a non-zero error code
    # when any changes are detected. This is actually a bit mask with
    # bits for new file detections, removed file detections, and changed
    # file detections. Error codes greater than 7 are other errors.
    [1, 2, 3, 4, 5, 6, 7]
  }

  hosts.each do |host|
    context 'with defaults' do
      let(:hieradata) { <<EOM
simp_options::auditd: false
simp_options::syslog: false
simp_options::logrotate: false
auditd::enable: false
EOM
      }
      
      it 'should install psmisc for killall' do
        # centos/7 box doesn't have psmisc installed by default
        install_package(host, 'psmisc')
      end

      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it "'aide' package should be installed" do
        check_for_package(host, 'aide')
      end

      it 'should generate the database' do
        on(host, 'ls /var/lib/aide/aide.db.gz')
      end

      it 'should generate an empty report when no problems are found' do
        on(host, '/usr/local/sbin/update_aide')
        on(host, '/usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to eq ''
      end

      it 'should generate a valid report when problems are found' do
        on(host, 'touch /etc/yum.conf')
        on(host, '/usr/sbin/aide --check', :acceptable_exit_codes => changes_detected)
        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.report")
        on(host, "grep 'changed: /etc/yum.conf' /var/log/aide/aide.report")
      end

      it 'should not generate /var/log/aide/aide.log' do
        on(host, 'ls /var/log/aide/aide.log', :acceptable_exit_codes => 2)
      end
    end

    context 'with syslog and logrotate enabled' do
      let(:hieradata) { <<EOM
simp_options::auditd: false
simp_options::syslog: true
simp_options::logrotate: true
aide::syslog_format: true
auditd::enable: false
EOM
       }

      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should generate an empty report and log nothing when no problems are found' do
        on(host, '/usr/local/sbin/update_aide')
        on(host, 'logrotate --force /etc/logrotate.d/aide')
        on(host, '/usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to eq ''
        log = on(host, 'cat /var/log/aide/aide.log').stdout
        expect(log).to eq ''
      end

      it 'should generate a valid report and log that report when problems are found' do
        on(host, 'touch /etc/yum.conf')
        on(host, '/usr/sbin/aide --check', :acceptable_exit_codes => changes_detected)

        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.report")
        on(host, "grep 'changed: /etc/yum.conf' /var/log/aide/aide.report")

        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.log")
        on(host, "grep 'changed: /etc/yum.conf' /var/log/aide/aide.log")
      end
    end
  end
end
