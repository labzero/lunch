require 'rails_helper'

describe DocusignService do
  let(:request) { double('request', uuid: '12345') }

  subject { DocusignService.new(request) }

  describe '`request` method' do
    it 'returns the request associated with the request' do
      expect(subject.request).to be(request)
    end
  end

  describe '`request_uuid` method' do
    it 'returns the UUID of the associated request' do
      uuid = double('Some UUID')
      allow(request).to receive(:uuid).and_return(uuid)
      expect(subject.request_uuid).to be(uuid)
    end
    it 'returns nil if the `request` is nil' do
      expect(DocusignService.new(nil).request_uuid).to be(nil)
    end
  end

  describe '`get_url` method' do
    let(:user_name) { SecureRandom.uuid }
    let(:email) { SecureRandom.uuid }
    let(:user) { double('Current User', display_name: user_name, email: email) }
    let(:member_id) { double('A Member ID') }
    let(:user_service) { double('user service instance') }
    let(:phone) { SecureRandom.uuid }
    let(:title) { SecureRandom.uuid }
    let(:user_details) { { :phone => phone, :title => title } }
    let(:member_service) { double('member service instance') }
    let(:company) { SecureRandom.uuid }
    let(:member_details) { { :name => company } }
    let(:powerform_endpoint) { 'demo.docusign.net' }
    let(:powerform_path) { '/Member/PowerFormSigning.aspx' }
    let(:form_name) { double('A Power Form Name') }
    let(:powerform_id) { SecureRandom.uuid }
    let(:powerform_mapping) { double(Hash) }
    let(:call_method) { subject.get_url(form_name, user, member_id) }
    before do
      allow(UsersService).to receive(:new).and_return(user_service)
      allow(user_service).to receive(:user_details).and_return(user_details)
      allow(MembersService).to receive(:new).and_return(member_service)
      allow(member_service).to receive(:member).and_return(member_details)
      stub_const("#{described_class}::POWERFORM_MAPPING", powerform_mapping)
      allow(powerform_mapping).to receive(:[]).and_return(nil)
      allow(powerform_mapping).to receive(:[]).with(form_name).and_return(powerform_id)
    end
    it 'returns docusing link with data from user service and member service' do
      expect(call_method[:link]).to eq(URI::HTTPS.build(:host => powerform_endpoint, :path => powerform_path, :query => {:PowerFormId => powerform_id, :Applicant_UserName => user_name, :Applicant_Email => email, :UName => user_name, :UCompany => company, :UEmail => email, :UPhone => phone, :UTitle => title}.to_query))
    end
    it 'returns docusing link with data from member service when user service does not find user' do
      allow(user_service).to receive(:user_details).and_return(nil)
      expect(call_method[:link]).to eq(URI::HTTPS.build(:host => powerform_endpoint, :path => powerform_path, :query => {:PowerFormId => powerform_id, :Applicant_UserName => user_name, :Applicant_Email => email, :UName => user_name, :UCompany => company, :UEmail => email, :UPhone => nil, :UTitle => nil}.to_query))
    end
    it 'returns docusing link with data from user service when member service does not find member' do
      allow(member_service).to receive(:member).and_return(nil)
      expect(call_method[:link]).to eq(URI::HTTPS.build(:host => powerform_endpoint, :path => powerform_path, :query => {:PowerFormId => powerform_id, :Applicant_UserName => user_name, :Applicant_Email => email, :UName => user_name, :UCompany => nil, :UEmail => email, :UPhone => phone, :UTitle => title}.to_query))
    end
    it 'raises an error if passed an unknown form name' do
      expect{subject.get_url(double('Unknown Form Name'), user, member_id)}.to raise_error(/unknown powerform/i)
    end
    describe 'user details' do
      [:phone, :title].each do |field|
        it "handles nil for `#{field}`" do
          user_details[field] = nil
          expect{call_method}.to_not raise_error
        end
      end
    end
    describe 'member details' do
      it "handles nil for `name`" do
        member_details[:name] = nil
        expect{call_method}.to_not raise_error
      end
    end
  end
end