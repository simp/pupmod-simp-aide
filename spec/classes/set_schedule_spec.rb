require 'spec_helper'

describe 'aide::set_schedule' do
  context 'supported operating systems' do
    on_supported_os.each_value do |os_facts|
      let(:pre_condition) do
        <<~PRECOND
          function assert_private(){}
        PRECOND
      end

      let(:facts) do
        os_facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('aide::set_schedule') }

      it do
        is_expected.to create_systemd__timer('puppet_aide.timer')
          .with_timer_content(%r{OnCalendar=Sun \*-\* 4:\d+})
          .with_service_content(%r{Type=oneshot})
          .with_service_content(%r{SuccessExitStatus=1 2 3 4 5 6 7})
          .with_service_content(%r{ExecStart=/bin/nice -n 19 /usr/sbin/aide --check})
          .with_active(true)
          .with_enable(true)
      end

      it { is_expected.to create_cron('aide_schedule').with_ensure('absent') }
      it { is_expected.to create_augeas('remove_aide_schedule') }

      context 'root mode' do
        let(:params) do
          {
            method: 'root'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('aide::set_schedule') }

        it do
          is_expected.to create_systemd__timer('puppet_aide.timer')
            .with_timer_content(%r{OnCalendar=Sun \*-\* 4:\d+})
            .with_service_content(%r{Type=oneshot})
            .with_service_content(%r{SuccessExitStatus=1 2 3 4 5 6 7})
            .with_service_content(%r{ExecStart=/bin/nice -n 19 /usr/sbin/aide --check})
            .with_active(false)
            .with_enable(false)
        end

        it do
          is_expected.to create_cron('aide_schedule')
            .with_command('/bin/nice -n 19 /usr/sbin/aide --check')
            .with_user('root')
            .with_minute(%r{\d+})
            .with_hour(4)
            .with_monthday('*')
            .with_month('*')
            .with_weekday(0)
        end

        it { is_expected.to create_augeas('remove_aide_schedule') }
      end

      context 'etc mode' do
        let(:params) do
          {
            method: 'etc'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('aide::set_schedule') }

        it do
          is_expected.to create_systemd__timer('puppet_aide.timer')
            .with_timer_content(%r{OnCalendar=Sun \*-\* 4:\d+})
            .with_service_content(%r{Type=oneshot})
            .with_service_content(%r{SuccessExitStatus=1 2 3 4 5 6 7})
            .with_service_content(%r{ExecStart=/bin/nice -n 19 /usr/sbin/aide --check})
            .with_active(false)
            .with_enable(false)
        end

        it { is_expected.to create_cron('aide_schedule').with_ensure('absent') }

        it { is_expected.to create_augeas('aide_schedule') }
        it { is_expected.to create_augeas('create_aide_schedule') }
        it { is_expected.to create_augeas('fix_aide_schedule') }
        it { is_expected.not_to create_augeas('remove_aide_schedule') }
      end
    end
  end
end
