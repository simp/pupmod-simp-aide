# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# Tests the `simp:defaults` Sicura Compliance Engine profile end to end: with
# `compliance_engine::enforcement: [simp:defaults]` set in Hiera, the otherwise
# no-op `include aide` must reproduce the configuration the module managed by
# default before the v9 blast-radius refactor.
#
# The "bare include is a no-op" regression specs live in init_spec.rb and are
# intentionally left untouched -- they guard the safe default when the profile
# is NOT enforced.
describe 'aide' do
  def self.profile_dir
    File.expand_path('../../SIMP/compliance_profiles', __dir__)
  end

  # --------------------------------------------------------------------------
  # Profile/check data integrity (no catalog compilation)
  # --------------------------------------------------------------------------
  context 'profile data' do
    let(:checks) { YAML.safe_load_file(File.join(self.class.profile_dir, 'checks.yaml'))['checks'] }
    let(:profile) { YAML.safe_load_file(File.join(self.class.profile_dir, 'profile-simp_defaults.yaml'))['profiles']['simp:defaults'] }

    it 'lists exactly the defined checks (no orphans, none missing)' do
      expect(profile['checks'].keys.sort).to eq(checks.keys.sort)
    end

    it 'only manages aide:: parameters' do
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params).to all(start_with('aide::'))
    end
  end

  # --------------------------------------------------------------------------
  # Enforced, no overrides: reproduces the pre-refactor catalog.
  # --------------------------------------------------------------------------
  context 'when enforcing simp:defaults' do
    let(:hiera_config) do
      File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
    end

    on_supported_os.each do |os, os_facts|
      major = os.split('-')[1]

      context "on #{os}" do
        let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_enforced', fips_enabled: false) }

        it { is_expected.to compile.with_all_deps }

        it 'installs the package' do
          is_expected.to contain_package('aide')
        end

        it 'manages the aide.conf directories and database lifecycle' do
          is_expected.to contain_file('/var/lib/aide').with_ensure('directory')
          is_expected.to contain_file('/var/log/aide').with_ensure('directory')
          is_expected.to contain_file('/usr/local/sbin/update_aide')
          is_expected.to contain_exec('update_aide_db')
          is_expected.to contain_exec('verify_aide_db_presence')
        end

        it 'manages the common aide.conf settings' do
          is_expected.to contain_file_line('aide.conf DBDIR').with_line('@@define DBDIR /var/lib/aide')
          is_expected.to contain_file_line('aide.conf LOGDIR').with_line('@@define LOGDIR /var/log/aide')
          is_expected.to contain_file_line('aide.conf database_out').with_line('database_out=file:@@{DBDIR}/aide.db.new.gz')
          is_expected.to contain_file_line('aide.conf gzip_dbout').with_line('gzip_dbout=yes')
          is_expected.to contain_file_line('aide.conf report_url file:@@{LOGDIR}/aide.report')
        end

        it 'writes the default ruleset and non-FIPS aliases' do
          is_expected.to contain_aide__rule('default')
          is_expected.to contain_file_line('aide.conf alias R').with_line('R = p+i+l+n+u+g+s+m+c+sha512')
        end

        if major == '8'
          it 'uses the AIDE 0.16 options (verbose + database)' do
            is_expected.to contain_file_line('aide.conf verbose').with_line('verbose=5')
            is_expected.to contain_file_line('aide.conf database').with_line('database=file:@@{DBDIR}/aide.db.gz')
            is_expected.not_to contain_file_line('aide.conf log_level')
            is_expected.not_to contain_file_line('aide.conf database_in')
          end
        else
          it 'uses the AIDE 0.19 options (log_level/report_level + database_in)' do
            is_expected.to contain_file_line('aide.conf log_level').with_line('log_level=warning')
            is_expected.to contain_file_line('aide.conf report_level').with_line('report_level=summary')
            is_expected.to contain_file_line('aide.conf database_in').with_line('database_in=file:@@{DBDIR}/aide.db.gz')
            is_expected.not_to contain_file_line('aide.conf verbose')
            is_expected.not_to contain_file_line('aide.conf database')
          end
        end
      end
    end

    context 'on a FIPS-enabled node' do
      let(:facts) do
        on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_enforced', fips_enabled: true)
      end

      it 'selects the FIPS-approved alias set' do
        is_expected.to contain_file_line('aide.conf alias R').with_line('R = p+i+l+n+u+g+s+m+c+sha1+sha256')
      end
    end
  end

  # --------------------------------------------------------------------------
  # `aide::dbdir` lookup check -- the rspec equivalent of
  # `puppet lookup aide::dbdir --compile` with and without enforcement.
  #
  # Binding the `aide::dbdir` class parameter is an implicit
  # `lookup('aide::dbdir')` through the compliance_engine Hiera backend; the
  # resolved value is observable as the `@@define DBDIR` line. With the profile
  # enforced the lookup yields the profile value; without it the lookup yields
  # nothing and no line is managed (the bare-include no-op).
  # --------------------------------------------------------------------------
  context 'aide::dbdir lookup through the compliance_engine backend' do
    let(:hiera_config) do
      File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
    end

    context 'with simp:defaults enforced' do
      let(:facts) do
        on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_enforced', fips_enabled: false)
      end

      it 'resolves to the profile value' do
        is_expected.to contain_file_line('aide.conf DBDIR').with_line('@@define DBDIR /var/lib/aide')
      end
    end

    context 'without enforcement' do
      let(:facts) do
        on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_disabled', fips_enabled: false)
      end

      it 'resolves to nothing (module default), leaving the bare include a no-op' do
        is_expected.to contain_package('aide')
        is_expected.not_to contain_file_line('aide.conf DBDIR')
      end
    end
  end

  # --------------------------------------------------------------------------
  # Enforced + explicit site override: the override (higher Hiera priority)
  # must win over the profile value (middle priority).
  # --------------------------------------------------------------------------
  context 'when an explicit Hiera value overrides the profile' do
    let(:hiera_config) do
      File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
    end
    let(:facts) do
      on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_with_override', fips_enabled: false)
    end

    it { is_expected.to compile.with_all_deps }

    it 'uses the overridden dbdir instead of the profile default' do
      is_expected.to contain_file_line('aide.conf DBDIR').with_line('@@define DBDIR /opt/custom/aide')
      is_expected.to contain_file('/opt/custom/aide').with_ensure('directory')
    end
  end
end
