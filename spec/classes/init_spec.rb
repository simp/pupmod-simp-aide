require 'spec_helper'

describe 'aide' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters (bare include)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('aide') }
        it { is_expected.to contain_package('aide').with_ensure('installed') }

        it 'manages only the aide package' do
          # Resource types Puppet always adds to a catalog, which are not
          # interesting when asserting a bare include manages nothing else.
          always_present = ['Class', 'Stage', 'Node', 'Filebucket', 'Schedule']
          managed = catalogue.resources.reject { |r| always_present.include?(r.type) }
          expect(managed.map(&:ref)).to eq(['Package[aide]'])
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
            .that_requires('Package[aide]')
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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/var/lib/aide').with_ensure('directory') }
        it { is_expected.to contain_file('/var/log/aide').with_ensure('directory') }
        it { is_expected.to contain_file('/usr/local/sbin/update_aide').with_content(%r{/usr/sbin/aide -c /etc/aide.conf}) }
        it { is_expected.to contain_exec('update_aide_db').with_command('/usr/local/sbin/update_aide').with_refreshonly(true) }
        it {
          is_expected.to contain_exec('verify_aide_db_presence')
            .with_command('/usr/local/sbin/update_aide')
            .with_onlyif('/usr/bin/test ! -f /var/lib/aide/aide.db.gz')
        }
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
