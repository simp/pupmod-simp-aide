require 'spec_helper'

describe 'aide' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:debian) { os_facts[:os][:family] == 'Debian' }
      let(:config_file) { debian ? '/etc/aide/aide.conf' : '/etc/aide.conf' }
      let(:packages) { debian ? ['aide', 'aide-common'] : ['aide'] }

      context 'with default parameters (bare include)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('aide') }
        it { is_expected.to contain_package('aide').with_ensure('installed') }

        if os_facts[:os][:family] == 'Debian'
          it { is_expected.to contain_package('aide-common').with_ensure('installed') }
        end

        it 'manages only the aide package(s)' do
          # Resource types Puppet always adds to a catalog, which are not
          # interesting when asserting a bare include manages nothing else.
          always_present = ['Class', 'Stage', 'Node', 'Filebucket', 'Schedule']
          managed = catalogue.resources.reject { |r| always_present.include?(r.type) }
          expect(managed.map(&:ref)).to eq(packages.map { |pkg| "Package[#{pkg}]" })
        end

        # Explicitly assert none of the previously-always-on behavior fires.
        it { is_expected.not_to contain_class('aide::default_rules') }
        it { is_expected.not_to contain_class('aide::set_schedule') }
        it { is_expected.not_to contain_class('aide::syslog') }
        it { is_expected.not_to contain_class('aide::logrotate') }
        it { is_expected.not_to contain_file('/usr/local/sbin/update_aide') }
        it { is_expected.not_to contain_file('/var/lib/aide') }
        it { is_expected.not_to contain_file('/var/log/aide') }
        it { is_expected.not_to contain_exec('update_aide_db') }
        it { is_expected.not_to contain_exec('verify_aide_db_presence') }
        it { is_expected.not_to contain_auditd__rule('aide') }
      end

      context 'with individual aide.conf fields set' do
        let(:params) do
          {
            dbdir:        '/var/lib/aide',
            logdir:       '/var/log/aide',
            database:     'file:@@{DBDIR}/aide.db.gz',
            database_out: 'file:@@{DBDIR}/aide.db.new.gz',
            gzip_dbout:   'yes',
            verbose:      5,
            report_urls:  ['file:@@{LOGDIR}/aide.report'],
            aliases:      ['NORMAL = R'],
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file_line('aide.conf DBDIR')
            .with_line('@@define DBDIR /var/lib/aide')
            .with_match('^@@define DBDIR\b')
            .with_ensure('present')
            .with_path(config_file)
            .that_requires(packages.map { |pkg| "Package[#{pkg}]" })
        }

        it { is_expected.to contain_file_line('aide.conf LOGDIR').with_line('@@define LOGDIR /var/log/aide') }

        it {
          is_expected.to contain_file_line('aide.conf database')
            .with_line('database=file:@@{DBDIR}/aide.db.gz')
            .with_match('^database=')
        }

        it { is_expected.to contain_file_line('aide.conf database_out').with_line('database_out=file:@@{DBDIR}/aide.db.new.gz') }
        it { is_expected.to contain_file_line('aide.conf gzip_dbout').with_line('gzip_dbout=yes') }
        it { is_expected.to contain_file_line('aide.conf verbose').with_line('verbose=5') }
        it { is_expected.to contain_file_line('aide.conf report_url file:@@{LOGDIR}/aide.report').with_line('report_url=file:@@{LOGDIR}/aide.report') }
        it { is_expected.to contain_file_line('aide.conf alias NORMAL').with_line('NORMAL = R').with_match('^NORMAL\s*=') }

        it 'does not manage the database without manage_database' do
          is_expected.not_to contain_exec('verify_aide_db_presence')
        end
      end

      context 'with version-specific database/log fields' do
        let(:params) do
          {
            database_in:  'file:@@{DBDIR}/aide.db.gz',  # AIDE >= 0.19
            log_level:    'warning',                    # AIDE >= 0.17
            report_level: 'summary',                    # AIDE >= 0.17
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file_line('aide.conf database_in')
            .with_line('database_in=file:@@{DBDIR}/aide.db.gz')
            .with_match('^database_in=')
            .that_requires('Package[aide]')
        }

        it { is_expected.to contain_file_line('aide.conf log_level').with_line('log_level=warning').with_match('^log_level=') }
        it { is_expected.to contain_file_line('aide.conf report_level').with_line('report_level=summary').with_match('^report_level=') }

        # database (<= 0.18) and verbose (<= 0.16) are not managed unless set
        it { is_expected.not_to contain_file_line('aide.conf database') }
        it { is_expected.not_to contain_file_line('aide.conf verbose') }
      end

      context 'removing the version-specific fields' do
        let(:params) do
          {
            database_in:  'absent',
            log_level:    'absent',
            report_level: 'absent',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file_line('aide.conf database_in').with_ensure('absent') }
        it { is_expected.to contain_file_line('aide.conf log_level').with_ensure('absent') }
        it { is_expected.to contain_file_line('aide.conf report_level').with_ensure('absent') }
      end

      context 'with a bad log_level value' do
        let(:params) { { log_level: 'not-a-level' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'log_level'}) }
      end

      context 'with verbose and log_level both set' do
        let(:params) { { verbose: 5, log_level: 'warning' } }

        it { is_expected.to compile.and_raise_error(%r{`verbose`.*cannot be combined with `log_level`/`report_level`}) }
      end

      context 'with verbose and report_level both set' do
        let(:params) { { verbose: 5, report_level: 'summary' } }

        it { is_expected.to compile.and_raise_error(%r{`verbose`.*cannot be combined with `log_level`/`report_level`}) }
      end

      context 'with database and database_in both set' do
        let(:params) do
          {
            database:    'file:@@{DBDIR}/aide.db.gz',
            database_in: 'file:@@{DBDIR}/aide.db.gz',
          }
        end

        it { is_expected.to compile.and_raise_error(%r{`database`.*and `database_in`.*cannot both be set}) }
      end

      context 'removing fields' do
        let(:params) do
          {
            gzip_dbout:        'absent',
            verbose:           'absent',
            dbdir:             'absent',
            report_urls_purge: ['file:@@{LOGDIR}/old.report'],
            aliases_purge:     ['LSPP'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file_line('aide.conf gzip_dbout').with_ensure('absent') }
        it { is_expected.to contain_file_line('aide.conf verbose').with_ensure('absent') }
        it { is_expected.to contain_file_line('aide.conf DBDIR').with_ensure('absent') }

        it {
          is_expected.to contain_file_line('aide.conf report_url file:@@{LOGDIR}/old.report absent')
            .with_ensure('absent')
            .with_line('report_url=file:@@{LOGDIR}/old.report')
        }

        it {
          is_expected.to contain_file_line('aide.conf alias LSPP absent')
            .with_ensure('absent')
            .with_match('^LSPP\s*=')
        }
      end

      context 'with syslog enabled' do
        let(:params) { { syslog: true } }

        it { is_expected.to contain_class('aide::syslog') }
        it {
          is_expected.to contain_file_line('aide.conf report_url syslog')
            .with_line('report_url=syslog:LOG_LOCAL6')
            .with_match('^report_url=syslog:')
        }
      end

      context 'with manage_database => true' do
        let(:params) { { manage_database: true } }

        # aide-common on Ubuntu 24.04 runs AIDE as `_aide`; EL and Ubuntu 22.04
        # run it as root.
        let(:aide_user) { (debian && os_facts[:os][:release][:major] != '22.04') ? '_aide' : nil }
        let(:dbdir_attrs) { aide_user ? { owner: '_aide', group: 'root', mode: '0700' } : { owner: 'root', group: 'root', mode: '0700' } }
        let(:logdir_attrs) { aide_user ? { owner: '_aide', group: 'adm', mode: '2755' } : { owner: 'root', group: 'root', mode: '0700' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/var/lib/aide').with_ensure('directory').with(dbdir_attrs).that_requires(packages.map { |pkg| "Package[#{pkg}]" }) }
        it { is_expected.to contain_file('/var/log/aide').with_ensure('directory').with(logdir_attrs).that_requires(packages.map { |pkg| "Package[#{pkg}]" }) }

        if os_facts[:os][:family] == 'Debian'
          it { is_expected.not_to contain_file('/usr/local/sbin/update_aide') }
          it {
            is_expected.to contain_exec('update_aide_db')
              .with_command('/usr/sbin/aideinit --yes --force')
              .with_refreshonly(true)
              .that_requires(['Package[aide]', 'Package[aide-common]', 'File[/var/lib/aide]', 'File[/var/log/aide]'])
          }
          it {
            is_expected.to contain_exec('verify_aide_db_presence')
              .with_command('/usr/sbin/aideinit --yes --force')
              .with_onlyif('/usr/bin/test ! -f /var/lib/aide/aide.db')
          }
        else
          it { is_expected.to contain_file('/usr/local/sbin/update_aide').with_content(%r{/usr/sbin/aide -c /etc/aide.conf}) }

          it 'writes the update_aide script' do
            is_expected.to contain_file('/usr/local/sbin/update_aide').with_content(<<~'SCRIPT')
              #!/bin/sh
              /usr/bin/killall -9 aide;
              wait;

              if [ -f /var/lib/aide/aide.db.gz ]; then
                /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -u;
              else
                /bin/nice -n 19 /usr/sbin/aide -c /etc/aide.conf -i;
              fi

              wait;
              cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

              # Need to report aide initialize/update failure. Since aide
              # update returns non-zero error codes even upon success, (return
              # codes 0 - 7), an easy way to determine an aide failure for
              # either initialization or update is to detect a copy failure. The
              # database out will not be created if the initialize/update fails.
              exit $?
            SCRIPT
          end

          it { is_expected.to contain_exec('update_aide_db').with_command('/usr/local/sbin/update_aide').with_refreshonly(true) }
          it {
            is_expected.to contain_exec('verify_aide_db_presence')
              .with_command('/usr/local/sbin/update_aide')
              .with_onlyif('/usr/bin/test ! -f /var/lib/aide/aide.db.gz')
              .that_requires(['Package[aide]', 'File[/usr/local/sbin/update_aide]', 'File[/var/lib/aide]', 'File[/var/log/aide]'])
          }
        end
      end

      context 'with auditd => true' do
        let(:params) { { auditd: true } }

        it { is_expected.to contain_auditd__rule('aide').with_content("-w #{config_file} -p wa -k CFG_aide") }
      end

      context 'with enable => true on the OS default command' do
        let(:params) { { enable: true } }

        it {
          aide_bin = debian ? '/usr/bin/aide --config=/etc/aide/aide.conf' : '/usr/sbin/aide'
          is_expected.to contain_systemd__timer('puppet_aide.timer')
            .with_service_content(%r{ExecStart=/bin/nice -n 19 #{aide_bin} --check})
        }
      end

      # The `$_db_notify` gating is a central safety invariant: editing an
      # aide.conf line must trigger the (disruptive) database rebuild *only*
      # when the module also owns the database (`manage_database => true`). On a
      # bare config edit the notify resolves to undef, so no rebuild fires. The
      # genuinely new coverage here is the notify *relationship* in both
      # directions, checked across two representative managed lines (DBDIR and
      # database_in) that share the same `notify => $_db_notify` wiring.
      context 'database-rebuild notification gating' do
        context 'a DBDIR edit with manage_database => false (default)' do
          let(:params) { { dbdir: '/var/lib/aide' } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('update_aide_db') }

          # `not_to ... that_notifies` passes vacuously if the resource is
          # absent, so assert the managed line exists before asserting it does
          # not notify a rebuild.
          it { is_expected.to contain_file_line('aide.conf DBDIR') }
          it { is_expected.not_to contain_file_line('aide.conf DBDIR').that_notifies('Exec[update_aide_db]') }
        end

        context 'a database_in edit with manage_database => false (default)' do
          let(:params) { { database_in: 'file:@@{DBDIR}/aide.db.gz' } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('update_aide_db') }

          it { is_expected.to contain_file_line('aide.conf database_in') }
          it { is_expected.not_to contain_file_line('aide.conf database_in').that_notifies('Exec[update_aide_db]') }
        end

        context 'a DBDIR edit with manage_database => true' do
          let(:params) { { dbdir: '/var/lib/aide', manage_database: true } }

          it { is_expected.to compile.with_all_deps }

          it 'notifies the database rebuild from the managed aide.conf line' do
            is_expected.to contain_file_line('aide.conf DBDIR').that_notifies('Exec[update_aide_db]')
          end
        end

        context 'a database_in edit with manage_database => true' do
          let(:params) { { database_in: 'file:@@{DBDIR}/aide.db.gz', manage_database: true } }

          it { is_expected.to compile.with_all_deps }

          it 'notifies the database rebuild from the managed aide.conf line' do
            is_expected.to contain_file_line('aide.conf database_in').that_notifies('Exec[update_aide_db]')
          end
        end
      end

      context 'with enable => true' do
        let(:params) { { enable: true } }

        it { is_expected.to contain_class('aide::set_schedule') }
      end

      context 'with a bad verbose value' do
        let(:params) { { verbose: 'definitely-not-an-integer' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'verbose'}) }
      end

      context 'with a bad gzip_dbout value' do
        let(:params) { { gzip_dbout: 'maybe' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'gzip_dbout'}) }
      end
    end
  end
end
