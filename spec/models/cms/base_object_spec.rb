require 'rails_helper'

RSpec.describe Cms::BaseObject, :type => :model do
  let(:request) { double('request') }
  let(:member_id) { rand(1000..9999) }
  let(:cms_key) { instance_double(Symbol) }
  let(:cms) { instance_double(ContentManagementService) }
  let(:subject) { Cms::BaseObject.new(member_id, request, cms_key, cms) }

  describe 'initialization' do
    before { allow(ContentManagementService).to receive(:new).and_return(cms) }

    it 'sets the `cms_key` attribute to the given `cms_key`' do
      expect(subject.cms_key).to eq(cms_key)
    end
    it 'sets the `cms` attribute to the given `cms` if one provided' do
      preexisting_cms = double('cms')
      subject = Cms::BaseObject.new(member_id, request, cms_key, preexisting_cms)
      expect(subject.cms).to eq(preexisting_cms)
    end
    context 'when a `cms` is not passed in during initialization' do
      let(:subject) { Cms::BaseObject.new(member_id, request, cms_key) }

      it 'creates a new instance of `ContentManagementService` with the member id and the request' do
        expect(ContentManagementService).to receive(:new).with(member_id, request)
        subject
      end
      it 'sets the `cms` attribute to the instance of `ContentManagementService` that was created' do
        allow(ContentManagementService).to receive(:new).and_return(cms)
        expect(subject.cms).to eq(cms)
      end
      it 'raises an error if an instance of `ContentManagementService` is not created' do
        allow(ContentManagementService).to receive(:new)
        expect{subject}.to raise_error(ArgumentError, 'Failed to create a valid instance of `ContentManagementService`')
      end
    end
  end
end