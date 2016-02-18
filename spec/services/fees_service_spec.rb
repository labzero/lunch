require 'rails_helper'

describe FeesService do
  subject { FeesService.new(double('request', uuid: '12345')) }
  
  describe '`fee_schedules` method' do
    let(:fee_schedules) { subject.fee_schedules }
    let(:response) { double('response') }
    it_should_behave_like 'a MAPI backed service object method', :fee_schedules
    it 'should call `get_hash` with the appropriate endpoint' do
      expect(subject).to receive(:get_hash).with(:fee_schedules, "fees/schedules")
      fee_schedules
    end
  end
  
end