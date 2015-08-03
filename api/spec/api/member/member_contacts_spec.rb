require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member member_contacts' do
    let(:member_contacts) { MAPI::Services::Member::Profile.member_contacts(subject, MEMBER_ID) }
    let(:processed_email) { double('the processed email address') }
    let(:downcased_username) { double('the downcased username') }
    let(:cam) {
      {
        "username" => double('cam username', downcase: downcased_username),
        "full_name" => double('cam full name'),
        "email" => double('cam email address')
      }
    }
    let(:rm) {
      {
        "full_name" => double('rm full name'),
        "email" => double('rm email', match: nil),
        "phone_number" => double('rm phone number')
      }
    }

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
          else
            allow(JSON).to receive(:parse).and_return({'cam' => cam}, {'rm' => rm})
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
            %w(full_name email).each do |attr|
              it "has an `#{attr}` attribute" do
                result_set = contact == 'cam' ? cam : rm
                expect(member_contacts[contact.to_sym][attr.to_sym]).to eq(result_set[attr])
              end
            end
            if contact == 'rm'
              it 'has a `phone_number` attribute' do
                expect(member_contacts[contact.to_sym][:phone_number]).to eq(rm['phone_number'])
              end
            end
          end
        end
        it 'sets the cam[\'username\'] to downcase' do
          expect(member_contacts[:cam][:username]).to eq(downcased_username)
        end
        it 'sets the rm[\'username\'] from the rm[\'email\'] after it has been processed' do
          allow(rm['email']).to receive(:match).and_return(double('match', captures: [double('captured match', downcase: processed_email)]))
          expect(member_contacts[:rm][:username]).to eq(processed_email)
        end
        it 'sets the cam[\'username\'] to the downcased version' do
          allow(cam['username']).to receive(:downcase).and_return(cam['username'])
          expect(member_contacts[:cam]['username']).to eq(cam['username'])
        end
      end
    end
  end
end
