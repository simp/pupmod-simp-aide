require 'spec_helper_acceptance'

test_name 'acpid class'

describe 'acpid class' do
  let(:manifest) {
    <<-EOS
      class { '::aide':
        enable => true
      }
    EOS
  }

  # We need this for our tests to run properly!
  on 'client', puppet('config set stringify_facts false')

  context 'with defaults' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
       apply_manifest(manifest, :catch_failures => true)
    end

    it 'should be idempotent' do
      apply_manifest(manifest, {:catch_changes => true})
    end

    describe package('aide') do
      it { is_expected.to be_installed }
    end

  end
end
