require 'spec_helper_acceptance'

# Needed for loading YAML later
require 'puppet'

test_name 'aide scheduling'

describe 'aide scheduling' do
  let(:manifest) do
    <<~MANIFEST
      include aide
    MANIFEST
  end

  let(:core_hieradata) do
    {
      'aide::enable'    => true,
      'aide::auditd'    => false,
      'aide::syslog'    => false,
      'aide::logrotate' => false,
      'auditd::enable'  => false,
    }
  end

  let(:hieradata) do
    core_hieradata
  end

  hosts.each do |host|
    context 'with defaults' do
      on(host, 'dnf install -y cronie')
      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'is running puppet_aide.timer' do
        output = on(host, 'puppet resource service puppet_aide.timer --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.timer']
        expect(service['ensure']).to eq 'running'
        # `enable` is deliberately not asserted via puppet resource: both units
        # ship no [Install] section, so they are static and the systemd
        # provider reports enable => 'true' unconditionally (see the cron-mode
        # notes below). Real enablement state is asserted on `systemctl
        # is-enabled` stdout instead -- never exit codes, which are 0 for
        # static units -- following the pattern from
        # https://github.com/simp/pupmod-simp-pupmod/pull/253.
      end

      it 'has puppet_aide.timer loaded into systemd' do
        result = on(host, 'systemctl list-timers --all --no-legend puppet_aide.timer').stdout
        expect(result).to include('puppet_aide.timer')
      end

      # These two pin the current, known-deficient enablement state: 'static'
      # means no [Install] section, so the timer is never linked into
      # timers.target.wants and will not come back after a reboot. When
      # https://github.com/simp/pupmod-simp-aide/issues/169 adds [Install]
      # sections, these will fail on that improvement and should be updated
      # (timer -> 'enabled').
      it 'reports puppet_aide.timer as static (no [Install] section, #169)' do
        result = on(host, 'systemctl is-enabled puppet_aide.timer', accept_all_exit_codes: true)
        expect(result.stdout.strip).to eq 'static'
      end

      it 'reports puppet_aide.service as static (no [Install] section, #169)' do
        result = on(host, 'systemctl is-enabled puppet_aide.service', accept_all_exit_codes: true)
        expect(result.stdout.strip).to eq 'static'
      end
    end

    context 'in "root" mode' do
      let(:hieradata) do
        core_hieradata.merge(
          {
            'aide::cron_method' => 'root',
            # Pin the schedule minute so the cron expectations below are
            # deterministic; the module default is fqdn_rand(59).
            'aide::minute'      => 22,
          },
        )
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'is not running puppet_aide.timer' do
        output = on(host, 'puppet resource service puppet_aide.timer --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.timer']
        expect(service['ensure']).to eq 'stopped'
        # NOTE: set_schedule.pp intends `enable => false` here, but the timer unit
        # has no [Install] section, so it is static -- `systemctl disable` is a
        # no-op on a static unit and `enable` always reports 'true'. Assert only
        # the deterministic guarantee (stopped); the module-side fix (give the
        # timer an [Install] section so it becomes disable-able) is tracked in
        # https://github.com/simp/pupmod-simp-aide/issues/169.
      end

      # No assertion on puppet_aide.service (the oneshot): nothing in the
      # catalog manages its run state (systemd::timer applies active/enable to
      # the timer unit only), and a oneshot reports `running` while
      # `aide --check` executes -- an `ensure` check here would measure
      # ambient state and flake if the live defaults-context timer fired
      # mid-suite. The enforced guarantee is the stopped timer above: a
      # stopped timer never triggers the oneshot. (Its `enable` is also
      # unassertable while the unit is static -- see
      # https://github.com/simp/pupmod-simp-aide/issues/169.)

      it 'has the root cron entry' do
        output = on(host, 'puppet resource cron aide_schedule --to_yaml').stdout
        cron = YAML.safe_load(output)['cron']['aide_schedule']
        expect(cron['command']).to eq '/bin/nice -n 19 /usr/sbin/aide --check'
        expect(cron['user']).to eq 'root'
        expect(cron['minute']).to eq ['22']
        expect(cron['hour']).to eq ['4']
        expect(cron['weekday']).to eq ['0']
      end
    end

    context 'in "etc" mode' do
      let(:hieradata) do
        core_hieradata.merge(
          {
            'aide::cron_method' => 'etc',
            # Pin the schedule minute so the /etc/crontab expectations and the
            # drift test (sed 22->21) below are deterministic; the module
            # default is fqdn_rand(59).
            'aide::minute'      => 22,
          },
        )
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do # rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'is not running puppet_aide.timer' do
        output = on(host, 'puppet resource service puppet_aide.timer --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.timer']
        expect(service['ensure']).to eq 'stopped'
        # NOTE: see the root-mode note above and
        # https://github.com/simp/pupmod-simp-aide/issues/169 -- the timer is
        # stopped in cron modes but stays static, so `enable` cannot be false.
      end

      # No assertion on puppet_aide.service -- see the root-mode note above.

      it 'does not have the root cron entry' do
        output = on(host, 'puppet resource cron aide_schedule --to_yaml').stdout
        cron = YAML.safe_load(output)['cron']['aide_schedule']
        expect(cron['ensure']).to eq 'absent'
      end

      it 'has the expected entry in /etc/crontab' do # rubocop:disable RSpec/RepeatedExample
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect(crontab.size).to eq 1
        expect(crontab.first.strip).to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check'
      end

      it 'adds an excess entry' do
        on(host, 'echo "* * * * * root /usr/sbin/aide --check" >> /etc/crontab')
      end

      it 'runs puppet' do # rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do # rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'does not have an excess entry' do # rubocop:disable RSpec/RepeatedExample
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect(crontab.size).to eq 1
        expect(crontab.first.strip).to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check'
      end

      it 'changes the current entry' do
        # Anchored to the aide entry: an unanchored global s/22/21/ would also
        # rewrite any unrelated '22' elsewhere in /etc/crontab, and the
        # aide-filtered assertions below would never detect that corruption.
        on(host, %q{sed -i -E 's|^22 (.*aide --check)$|21 \1|' /etc/crontab})
      end

      it 'runs puppet' do # rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do # rubocop:disable RSpec/RepeatedExample, RSpec/RepeatedDescription
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has a corrected entry' do # rubocop:disable RSpec/RepeatedExample
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect(crontab.size).to eq 1
        expect(crontab.first.strip).to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check'
      end
    end
  end
end
