require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member member_contacts' do
    let(:member_contacts) { MAPI::Services::Member::Profile.member_contacts(subject, MEMBER_ID) }
    let(:cam) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['CAM'] }
    let(:rm) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['RM'] }

    it 'calls the `member_contacts` method when the endpoint is hit' do
      allow(MAPI::Services::Member::Profile).to receive(:member_contacts).and_return('a response')
      get "/member/#{MEMBER_ID}/member_contacts"
      expect(last_response.status).to eq(200)
    end

    [:test, :production].each do |env|
      describe "`member_contacts` method in the #{env} environment" do
        let(:query_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production

        before do
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(query_result_set)
            allow(query_result_set).to receive(:fetch_hash).and_return(cam, rm)
          end
        end
        it 'returns an object with an `cam`' do
          expect(member_contacts[:cam]).to be_kind_of(Hash)
        end
        it "returns an object with a `rm`" do
          expect(member_contacts[:rm]).to be_kind_of(Hash)
        end
        %w(cam rm).each do |contact|
          describe "the `#{contact}` hash" do
            %w(FULL_NAME EMAIL USERNAME).each do |attr|
              it "has an `#{attr}` attribute" do
                expect(member_contacts[contact.to_sym][attr]).to be_kind_of(String)
              end
            end
            if contact == 'rm'
              it 'has a `PHONE_NUMBER` attribute' do
                expect(member_contacts[contact.to_sym]['PHONE_NUMBER']).to be_kind_of(String)
              end
            end
          end
        end
      end
    end
  end
end
