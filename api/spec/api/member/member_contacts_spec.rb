require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member member_contacts' do
    let(:member_contacts) { MAPI::Services::Member::Profile.member_contacts(subject, MEMBER_ID) }
    let(:processed_email) { double('the processed email address') }
    let(:cam) {
      {
        "USERNAME" => double('cam username', downcase: self),
        "FULL_NAME" => double('cam full name'),
        "EMAIL" => double('cam email address')
      }
    }
    let(:rm) {
      {
        "FULL_NAME" => double('rm full name'),
        "EMAIL" => double('rm EMAIL', match: nil),
        "PHONE_NUMBER" => double('rm phone number')
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
            allow(JSON).to receive(:parse).and_return({'CAM' => cam}, {'RM' => rm})
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
                result_set = contact == 'cam' ? cam : rm
                expect(member_contacts[contact.to_sym][attr]).to eq(result_set[attr])
              end
            end
            if contact == 'rm'
              it 'has a `PHONE_NUMBER` attribute' do
                expect(member_contacts[contact.to_sym]['PHONE_NUMBER']).to eq(rm['PHONE_NUMBER'])
              end
            end
          end
        end
        it 'sets the rm[\'USERNAME\'] from the rm[\'EMAIL\'] after it has been processed' do
          allow(rm['EMAIL']).to receive(:match).and_return(double('match', captures: [double('caputured match', downcase: processed_email)]))
          expect(member_contacts[:rm]['USERNAME']).to eq(processed_email)
        end
        it 'sets the cam[\'USERNAME\'] to the downcased version' do
          allow(cam['USERNAME']).to receive(:downcase).and_return(cam['USERNAME'])
          expect(member_contacts[:cam]['USERNAME']).to eq(cam['USERNAME'])
        end
      end
    end
  end
end
