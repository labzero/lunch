require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'GET /member/:member_id/signers' do
    it 'calls `MAPI::Services::Member::SignerRoles.signer_roles`' do
      expect(MAPI::Services::Member::SignerRoles).to receive(:signer_roles)
      get "/member/#{MEMBER_ID}/signers"
    end
    it 'returns a JSON object' do
      response_obj = double('Response Object')
      allow(MAPI::Services::Member::SignerRoles).to receive(:signer_roles).and_return(response_obj)
      expect(response_obj).to receive(:to_json)
      get "/member/#{MEMBER_ID}/signers"
    end
  end

  describe 'the `signer_roles` method' do
    let(:app) {double('App', :settings => double('settings', :environment => nil))}
    let(:signer_roles) {MAPI::Services::Member::SignerRoles.signer_roles(app, MEMBER_ID)}

    [:test, :production].each do |env|
      describe "in the #{env} environment" do
        let(:signer_roles_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:roles) {['signer', 'signer-etransact']}
        let(:last_name)  { 'Access' }
        let(:first_name) { 'Chaste' }
        let(:signer_roles_result) {[{'FULLNAME' => 'Chaste Access', 'LOGIN_ID' =>'extra-chaste-access', 'FNAME' => first_name, 'LNAME' => last_name}, nil]} if env == :production
        before do
          allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'signer_roles.json')))) if env == :test
          allow(app.settings).to receive(:environment).and_return(env)
          allow(MAPI::Services::Users).to receive(:process_roles).and_return(roles) if env == :production
          if env == :production
            expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(signer_roles_result_set)
            allow(signer_roles_result_set).to receive(:fetch_hash).and_return(*signer_roles_result)
          end
        end

        it 'returns an array' do
          expect(signer_roles).to be_kind_of(Array)
        end
        describe 'signer objects in the response array' do
          it 'has a name attribute' do
            signer_roles.each do |signer|
              expect(signer[:name]).to be_kind_of(String)
            end
          end
          it 'has a username attribute' do
            signer_roles.each do |signer|
              expect(signer[:username]).to be_kind_of(String)
            end
          end
          it 'has a roles attribute' do
            signer_roles.each do |signer|
              expect(signer[:roles]).to be_kind_of(Array)
              signer[:roles].each do |role|
                expect(role).to be_kind_of(String)
              end
            end
          end
          it 'has a last name attribute' do
            signer_roles.each do |signer|
              expect(signer[:last_name]).to be(last_name)
            end
          end
          it 'has a first name attribute' do
            signer_roles.each do |signer|
              expect(signer[:first_name]).to be(first_name)
            end
          end
        end
      end
    end
  end
end
