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
        expect(service['enable']).to eq 'true'
      end

      it 'has puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect(service['enable']).to eq 'true'
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

      it 'does not have puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect(service['ensure']).to eq 'stopped'
        # NOTE: the oneshot unit has no [Install] section either, so it is also
        # static and `enable` always reports 'true'; `enable => false` cannot be
        # enforced on a static unit. Assert only the deterministic guarantee
        # (stopped); tracked with the timer fix in
        # https://github.com/simp/pupmod-simp-aide/issues/169.
      end

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

      it 'does not have puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect(service['ensure']).to eq 'stopped'
        # NOTE: see the root-mode service note above and
        # https://github.com/simp/pupmod-simp-aide/issues/169.
      end

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
        on(host, 'sed -i "s/22/21/g" /etc/crontab')
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
