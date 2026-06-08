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

  # A full configuration that reproduces a working, self-managed AIDE setup.
  # Under the new model none of this happens on a bare `include aide`; the
  # operator opts in explicitly.
  #
  # The aide.conf option names changed across AIDE versions, so the config is
  # chosen per-host: EL > 8 ships AIDE 0.19+ (database_in, log_level/report_level)
  # while EL 8 ships AIDE 0.16 (database, verbose). (AlmaLinux 9 ships aide
  # 0.19.2, which rejects the legacy `database`/`verbose` options.)
  def full_config(host)
    major = host[:platform].to_s.split('-')[1].to_i

    version_opts = if major > 8
                     {
                       'aide::database_in'  => 'file:@@{DBDIR}/aide.db.gz',
                       'aide::log_level'    => 'warning',
                       'aide::report_level' => 'summary',
                     }
                   else
                     {
                       'aide::database' => 'file:@@{DBDIR}/aide.db.gz',
                       'aide::verbose'  => 5,
                     }
                   end

    {
      'aide::manage_database' => true,
      'aide::dbdir'           => '/var/lib/aide',
      'aide::logdir'          => '/var/log/aide',
      'aide::database_out'    => 'file:@@{DBDIR}/aide.db.new.gz',
      'aide::gzip_dbout'      => 'yes',
      'aide::report_urls'     => ['file:@@{LOGDIR}/aide.report'],
      # The package-shipped /etc/aide.conf ships `report_url=file:@@{LOGDIR}/aide.log`
      # (true on both EL8 AIDE 0.16 and EL9/EL10 AIDE 0.19). The new module manages
      # individual lines and leaves that one untouched, so AIDE would also write
      # aide.log. Purge it so the report goes only to the configured aide.report.
      'aide::report_urls_purge' => ['file:@@{LOGDIR}/aide.log'],
      'aide::aliases' => [
        'R = p+i+l+n+u+g+s+m+c+sha512',
        'NORMAL = R',
        'PERMS = p+i+u+g+acl',
        'LOG = >',
      ],
      'aide::default_rules' => [
        '/bin    NORMAL',
        '/sbin   NORMAL',
        '/etc    PERMS',
        '/var/log   LOG',
        '!/var/log/aide/aide.log',
        '!/var/log/aide/aide.report',
      ],
      'aide::auditd'    => false,
      'aide::syslog'    => false,
      'aide::logrotate' => false,
      'auditd::enable'  => false,
    }.merge(version_opts)
  end

  hosts.each do |host|
    context 'a bare include is a safe no-op beyond the package' do
      let(:hieradata) { {} }

      it 'installs psmisc for killall' do
        install_package(host, 'psmisc')
      end

      it 'applies with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it "'aide' package should be installed" do
        check_for_package(host, 'aide')
      end

      it 'does not initialize the AIDE database' do
        on(host, 'ls /var/lib/aide/aide.db.gz', acceptable_exit_codes: [1, 2])
      end

      it 'does not install the update_aide helper' do
        on(host, 'ls /usr/local/sbin/update_aide', acceptable_exit_codes: [1, 2])
      end
    end

    context 'with a full configuration' do
      let(:hieradata) { full_config(host) }

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'generates the database' do
        on(host, 'ls /var/lib/aide/aide.db.gz')
      end

      it 'retains the output database for SCAP xccdf_org.ssgproject.content_rule_aide_build_database' do
        on(host, 'ls /var/lib/aide/aide.db.new.gz')
      end

      it 'generates an empty or clean report when no problems are found' do
        on(host, '/usr/local/sbin/update_aide; /usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to match(%r{^(.+NO differences.+)?$})
      end

      it 'generates a valid report when problems are found' do
        on(host, 'mv /etc/yum.conf /etc/yum.conf.bak') if file_exists_on(host, '/etc/yum.conf')
        on(host, 'mv /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak') if file_exists_on(host, '/etc/dnf/dnf.conf')
        on(host, '/usr/sbin/aide --check', acceptable_exit_codes: changes_detected)
        on(host, "grep 'found differences between database and filesystem' /var/log/aide/aide.report")
        on(host, 'mv /etc/yum.conf.bak /etc/yum.conf') if file_exists_on(host, '/etc/yum.conf.bak')
        on(host, 'mv /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf') if file_exists_on(host, '/etc/dnf/dnf.conf.bak')
      end

      it 'does not generate /var/log/aide/aide.log' do
        on(host, 'ls /var/log/aide/aide.log', acceptable_exit_codes: 2)
      end
    end

    context 'with syslog and logrotate enabled' do
      let(:hieradata) do
        full_config(host).merge(
          'aide::syslog'    => true,
          'aide::logrotate' => true,
          # Unlike the no-logging full_config above, keep the package-shipped
          # report_url=file:@@{LOGDIR}/aide.log so AIDE writes aide.log for the
          # logrotate test below to rotate.
          'aide::report_urls_purge' => [],
        )
      end

      it 'works with no errors' do
        on(host, '/usr/bin/dnf install -y logrotate')
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
        # rsyslog changes require a second run
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'generates an empty or clean report and log nothing when no problems are found' do
        on(host, 'logrotate --force /etc/logrotate.simp.d/aide')
        on(host, '/usr/local/sbin/update_aide')
        on(host, '/usr/sbin/aide --check')
        report = on(host, 'cat /var/log/aide/aide.report').stdout
        expect(report).to match(%r{^(.+NO differences.+)?$})
        log = on(host, 'cat /var/log/aide/aide.log').stdout
        expect(log).to match(%r{^(.+NO differences.+)?$})
      end
    end
  end
end
