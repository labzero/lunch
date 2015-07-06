require 'rails_helper'

describe MembersService do
  let(:member_id) { 3 }
  subject { MembersService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:report_disabled?) }

  describe '`report_disabled?` method' do
    let(:report_flags) {[5, 7]}
    let(:response_object) { double('Response')}
    let(:report_disabled?) {subject.report_disabled?(member_id, report_flags)}

    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(report_disabled?).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(report_disabled?).to eq(nil)
    end

    describe 'hitting the MAPI endpoint' do
      let(:request_object) {double('Request')}
      let(:overlapping_response) {[7, 9].to_json}
      let(:non_overlapping_response) {[2, 9].to_json}

      before do
        expect(request_object).to receive(:get).and_return(response_object)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{member_id}/disabled_reports").and_return(request_object)
      end
      it 'returns true if any of the values it was passed in the report_flags array match any values returned by MAPI' do
        expect(response_object).to receive(:body).and_return(overlapping_response)
        expect(report_disabled?).to be(true)
      end
      it 'returns false if none of the values it was passed in the report_flags array match values returned by MAPI' do
        expect(response_object).to receive(:body).and_return(non_overlapping_response)
        expect(report_disabled?).to be(false)
      end
      it 'returns false if the MAPI endpoint passes back an empty array' do
        expect(response_object).to receive(:body).and_return([].to_json)
        expect(report_disabled?).to be(false)
      end
    end
  end

  describe '`all_members` method', :vcr do
    let(:members) { subject.all_members }
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(members).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(members).to eq(nil)
    end
    it 'returns an array of members on success' do
      expect(members).to be_kind_of(Array)
      expect(members.count).to be >= 1
      members.each do |member|
        expect(member).to be_kind_of(Hash)
        expect(member[:id]).to be_kind_of(Numeric)
        expect(member[:id]).to be > 0
        expect(member[:name]).to be_kind_of(String)
        expect(member[:name]).to be_present
      end
    end
  end

  describe '`member` method', :vcr do
    let(:member) { subject.member(member_id) }
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(member).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(member).to eq(nil)
    end
    it 'returns a member on success' do
      expect(member).to be_kind_of(Hash)
      expect(member[:id]).to be_kind_of(Numeric)
      expect(member[:id]).to be > 0
      expect(member[:name]).to be_kind_of(String)
      expect(member[:name]).to be_present
    end
  end

  describe 'ldap backed methods' do
    let(:ldap_connection) { double('LDAP Connection', search: []) }
    before do
      allow(Devise::LDAP::Connection).to receive(:admin).with('extranet').and_return(ldap_connection)
      allow(ldap_connection).to receive(:open).and_yield(ldap_connection)
    end

    describe '`users` method' do
      let(:users) { subject.users(member_id) }
      let(:dn) { double('A DN', end_with?: true) }
      let(:user_entry) { double('LDAP Entry: User', dn: dn, :[] => nil) }
      let(:group_entry) { obj = double('LDAP Entry: Group'); allow(obj).to receive(:[]).with(:member).and_return([dn]); obj }
      before do
        allow(ldap_connection).to receive(:search).with(filter: "(&(CN=FHLB#{member_id.to_i})(objectClass=group))").and_return([group_entry])
        allow(ldap_connection).to receive(:search).with(base: dn, scope: Net::LDAP::SearchScope_BaseObject).and_return([user_entry])
        allow(User).to receive(:find_or_create_by_ldap_entry).and_return(User.new)
      end
      it 'should open an admin LDAP connection to the extranet LDAP server' do
        expect(Devise::LDAP::Connection).to receive(:admin).with('extranet')
        users
      end
      it 'should search for the member banks LDAP group' do
        expect(ldap_connection).to receive(:search).with(filter: "(&(CN=FHLB#{member_id.to_i})(objectClass=group))")
        users
      end
      it 'should grab the members of the member banks group' do
        expect(ldap_connection).to receive(:search).with(base: dn, scope: Net::LDAP::SearchScope_BaseObject)
        users
      end
      it 'should return an array of Users' do
        expect(users.count).to be > 0
        users.each do |user|
          expect(user).to be_kind_of(User)
        end
      end
      it 'should lookup the User record or create it if not found' do
        expect(User).to receive(:find_or_create_by_ldap_entry).with(user_entry)
        users
      end
    end

    describe '`signers_and_users` method' do
      let(:signer_mapped_roles) {[User::ROLE_MAPPING['signer-etransact']]}
      let(:signer_roles) {['signer-etransact']}
      let(:signer) {{name: 'Some Signer', roles: signer_roles}}
      let(:duplicate_signer) {{name: 'A Duplicate User', username: 'username', roles: signer_roles}}
      let(:user_roles) {['user']}
      let(:user) {double('Some User', :display_name => 'User Display Name', roles: user_roles, username: 'username')}
      let(:member) { subject.signers_and_users(member_id) }

      it 'should return nil if there was an API error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(member).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(member).to eq(nil)
      end

      describe 'returns an array' do
        before do
          allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(double('MAPI response', body: [signer].to_json))
          allow(subject).to receive(:fetch_ldap_users).and_return([user])
        end
        it 'contains hashes with with a `display_name` and `roles` representing all users associated with a bank' do
          expect(member).to include({:display_name => 'User Display Name', roles: user_roles})
        end
        it 'contains hashes with with a `display_name` and `roles` representing all signers associated with a bank' do
          expect(member).to include({:display_name => 'Some Signer', roles: signer_mapped_roles})
        end
        it 'does not add a signer to the result set if the signer is also a user' do
          allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(double('MAPI response', body: [signer, duplicate_signer].to_json))
          expect(member.length).to eq(2)
        end
        it 'returns an empty array if no users or signers are found' do
          allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(double('MAPI response', body: '[]'))
          allow(subject).to receive(:fetch_ldap_users).and_return([])
          expect(member).to eq([])
        end
      end
    end
  end
end
