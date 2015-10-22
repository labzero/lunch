require 'rails_helper'

describe FHLBMember::FailureApp do
  it 'is a subclass of the Devise::FailureApp' do
    expect(subject).to be_kind_of(Devise::FailureApp)
  end

  describe '`store_location!` protected method' do
    let(:call_method) { subject.send(:store_location!) }

    before do
      allow(subject).to receive(:request).and_return(ActionDispatch::TestRequest.new)
      allow(subject).to receive(:scope)
      allow(subject).to receive(:attempted_path)
    end

    it 'calls super if the request is not an XHR request' do
      expect_any_instance_of(Devise::FailureApp).to receive(:store_location_for)
      call_method
    end

    it 'does not call super if the request is an XHR request' do
      allow(subject.request).to receive(:xhr?).and_return(true)
      expect_any_instance_of(Devise::FailureApp).to_not receive(:store_location_for)
      call_method
    end
  end
end