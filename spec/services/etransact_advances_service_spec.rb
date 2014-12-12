require 'spec_helper'

describe EtransactAdvancesService do
  subject { EtransactAdvancesService.new }
  it { expect(subject).to respond_to(:etransact_active?) }
  describe '`etransact_active? method`' do
    let(:status) {subject.etransact_active?}
    it 'returns a boolean' do
      expect(status).to (be true).or(be false)
    end
  end
end