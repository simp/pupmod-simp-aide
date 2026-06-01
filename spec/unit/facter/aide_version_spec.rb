require 'spec_helper'
require 'facter'

describe 'aide_version fact' do
  let(:fact_file) do
    File.expand_path(File.join(__dir__, '..', '..', '..', 'lib', 'facter', 'aide_version.rb'))
  end

  before(:each) { Facter.clear }
  after(:each) { Facter.clear }

  # (Re)load the fact definition after each Facter.clear so confines/setcode
  # are registered against the current set of stubs.
  def resolved_value
    load fact_file
    Facter.fact(:aide_version)&.value
  end

  context 'when AIDE is not installed' do
    before(:each) do
      allow(Facter::Core::Execution).to receive(:which).with('aide').and_return(nil)
    end

    it 'is unresolved (nil)' do
      expect(resolved_value).to be_nil
    end
  end

  context 'when AIDE is installed' do
    before(:each) do
      allow(Facter::Core::Execution).to receive(:which).with('aide').and_return('/usr/sbin/aide')
    end

    it 'returns the two-component version for AIDE 0.16' do
      allow(Facter::Core::Execution).to receive(:execute)
        .and_return("Aide 0.16\nCompiled with the following options:\n")
      expect(resolved_value).to eq('0.16')
    end

    it 'returns the three-component version for AIDE 0.17.4' do
      allow(Facter::Core::Execution).to receive(:execute)
        .and_return("Aide 0.17.4\nCompiled with the following options:\n")
      expect(resolved_value).to eq('0.17.4')
    end

    it 'parses a lower-case binary name' do
      allow(Facter::Core::Execution).to receive(:execute)
        .and_return("aide 0.18\n")
      expect(resolved_value).to eq('0.18')
    end

    it 'is nil when the version cannot be parsed' do
      allow(Facter::Core::Execution).to receive(:execute)
        .and_return('unexpected output')
      expect(resolved_value).to be_nil
    end
  end
end
