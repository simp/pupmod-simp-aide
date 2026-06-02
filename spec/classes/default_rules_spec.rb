require 'spec_helper'

# We have to test aide::default_rules via aide, because aide::default_rules
# is private.  To take advantage of hooks built into puppet-rspec, the class
# described needs to be the class instantiated, i.e., aide.
#
# The curated ruleset is no longer shipped as auto-applied Hiera data, so the
# tests pass `default_rules` explicitly.
describe 'aide' do
  on_supported_os.each do |os, os_facts|
    context "supported #{os}" do
      let(:facts) { os_facts }

      context 'when default_rules is unset (bare include)' do
        it { is_expected.not_to contain_class('aide::default_rules') }
        it { is_expected.not_to contain_aide__rule('default') }
      end

      context 'with an array of default rules' do
        let(:params) do
          {
            default_rules: [
              '/boot   NORMAL',
              '/bin    NORMAL',
              '/etc    PERMS',
            ],
          }
        end

        it { is_expected.to contain_class('aide::default_rules') }
        it { is_expected.to contain_aide__rule('default').with_ruledir('/etc/aide.conf.d') }
        it {
          is_expected.to contain_aide__rule('default')
            .with_rules("/boot   NORMAL\n/bin    NORMAL\n/etc    PERMS")
        }
      end

      context 'with custom ruledir' do
        let(:params) { { default_rules: ['/bin NORMAL'], ruledir: '/etc/aide.d' } }

        it { is_expected.to contain_aide__rule('default').with_ruledir('/etc/aide.d') }
      end

      context 'with a string of default rules' do
        let(:custom_rules) { "/bin HIGH\n/sbin HIGH" }
        let(:params) { { default_rules: custom_rules } }

        it { is_expected.to contain_aide__rule('default').with_rules(custom_rules) }
      end
    end
  end
end
