require 'spec_helper_acceptance'

# Needed for loading YAML later
require 'puppet'

test_name 'aide scheduling'

describe 'aide scheduling' do
  let(:manifest) do
    <<-MANIFEST
      include aide
    MANIFEST
  end

  let(:core_hieradata) do
    {
      'aide::enable' => true,
    'simp_options::auditd'    => false,
    'simp_options::syslog'    => false,
    'simp_options::logrotate' => false,
    'auditd::enable'          => false,
    }
  end

  let(:hieradata) do
    core_hieradata
  end

  hosts.each do |host|
    context 'with defaults' do
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
        expect { service['ensure'].to eq 'running' }
        expect { service['enable'].to eq 'true' }
      end

      it 'has puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect { service['enable'].to eq 'true' }
      end
    end

    context 'in "root" mode' do
      let(:hieradata) do
        core_hieradata.merge(
          {
            'aide::cron_method' => 'root'
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
        expect { service['ensure'].to eq 'stopped' }
        expect { service['enable'].to eq 'false' }
      end

      it 'does not have puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect { service['ensure'].to eq 'stopped' }
        expect { service['enable'].to eq 'false' }
      end

      it 'has the root cron entry' do
        output = on(host, 'puppet resource cron aide_schedule --to_yaml').stdout
        cron = YAML.safe_load(output)['cron']['aide_schedule']
        expect { cron['command'].to eq '/bin/nice -n 19 /usr/sbin/aide --check' }
        expect { cron['user'].to eq 'root' }
        expect { cron['minute'].to eq ['22'] }
        expect { cron['hour'].to eq ['4'] }
        expect { cron['weekday'].to eq ['0'] }
      end
    end

    context 'in "etc" mode' do
      let(:hieradata) do
        core_hieradata.merge(
          {
            'aide::cron_method' => 'etc'
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
        expect { service['ensure'].to eq 'stopped' }
        expect { service['enable'].to eq 'false' }
      end

      it 'does not have puppet_aide.service loaded' do
        output = on(host, 'puppet resource service puppet_aide.service --to_yaml').stdout
        service = YAML.safe_load(output)['service']['puppet_aide.service']
        expect { service['ensure'].to eq 'stopped' }
        expect { service['enable'].to eq 'false' }
      end

      it 'does not have the root cron entry' do
        output = on(host, 'puppet resource cron aide_schedule --to_yaml').stdout
        cron = YAML.safe_load(output)['cron']['aide_schedule']
        expect { cron['ensure'].to eq 'absent' }
      end

      it 'has the expected entry in /etc/crontab' do
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect { crontab.size.to eq 1 }
        expect { crontab.first.strip to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check' }
      end

      it 'adds an excess entry' do
        on(host, 'echo "* * * * * root /usr/sbin/aide --check" >> /etc/crontab')
      end

      it 'runs puppet' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'runs be idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'does not have an excess entry' do
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect { crontab.size.to eq 1 }
        expect { crontab.first.strip to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check' }
      end

      it 'changes the current entry' do
        on(host, 'sed -i "s/22/21/g" /etc/crontab')
      end

      it 'runs puppet' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'runs be idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has a corrected entry' do
        crontab = file_contents_on(host, '/etc/crontab').lines.select { |x| x.include?('aide') }

        expect { crontab.size.to eq 1 }
        expect { crontab.first.strip to eq '22 4 * * 0 root /bin/nice -n 19 /usr/sbin/aide --check' }
      end
    end
  end
end
