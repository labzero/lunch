require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'GET /users/:username/roles' do
    let(:username) { 'local' }
    let(:make_request) { get "/users/#{username}/roles" }
    let(:json) { make_request; JSON.parse(last_response.body) }
    let(:signer_id_cursor) { double('Signer ID Query Cursor', fetch: nil) }
    let(:roles_cursor) { double('Roles Query Cursor', fetch: nil) }
    let(:signer_id) { id = double('A Signer ID'); allow(id).to receive(:to_i).and_return(id); id }
    [:test, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(subject.settings).to receive(:environment).and_return(env)
        end
        it 'returns a 404 if no username is supplied' do
          get '/users//roles'
          expect(last_response.status).to eq(404)
        end
        it 'returns a 404 if a unknown username is supplied' do
          get '/users/foobar/roles'
          expect(last_response.status).to eq(404)
        end
        it 'returns a 200 if a known user is supplied' do
          make_request
          expect(last_response.status).to eq(200)
        end
        it 'returns an JSON encoded array of roles on success' do
          expect(json).to match_array(['signer-advances', 'signer'])
        end
      end
    end
    describe 'in the `production` environment' do
      before do
        allow(subject.settings).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(signer_id_cursor, roles_cursor)
        allow(signer_id_cursor).to receive(:fetch).and_yield([signer_id])
        allow(roles_cursor).to receive(:fetch_hash).and_yield({})
      end
      it 'returns a 404 if no username is supplied' do
        get '/users//roles'
        expect(last_response.status).to eq(404)
      end
      it 'returns a 404 if a unknown username is supplied' do
        allow(signer_id_cursor).to receive(:fetch)
        get '/users/foobar/roles'
        expect(last_response.status).to eq(404)
      end
      it 'returns a 200 if a known user is supplied' do
        make_request
        expect(last_response.status).to eq(200)
      end
      it 'returns an JSON encoded array of roles on success' do
        allow(roles_cursor).to receive(:fetch_hash).and_yield({'ADVSIGNER' => -1})
        expect(json).to match_array(['signer-advances', 'signer'])
      end
      role_mapping = {
        'ADVSIGNER' => ['signer-advances'],
        'COLLATSIGNER' => ['signer-collateral'],
        'MNYMKTSIGNER' => ['signer-moneymarket'],
        'SWAPSIGNER' => ['signer-creditswap'],
        'SECURITYSIGNER' => ['signer-securities'],
        'WIRESIGNER' => ['signer-wiretransfers'],
        'REPOSIGNER' => ['signer-repurchaseagreement'],
        'AFFORDABITYSIGNER' => ['signer-affordability']
      }
      role_mapping.each do |column, roles|
        it "returns the correct roles (#{roles.join(', ')}, signer) when the signer has the column `#{column}` set to -1" do
          column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
          column_hash[column] = -1
          column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'N'
          allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
          expect(json).to match_array(roles.dup << 'signer' )
        end
        it 'does not include the roles (#{roles.join(', '), signer-manager}) when the signer has the column `#{column}` set to 0' do
          column_hash = Hash[role_mapping.keys.collect {|key| [key, -1]}]
          column_hash[column] = 0
          allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
          expect(json).not_to include(*(roles + ['signer-manager']))
        end
      end
      it 'returns all the roles except `signer-manager` when the signer has the column `ALLPRODUCT` set to -1' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        column_hash['ALLPRODUCT'] = -1
        column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'N'
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to match_array(role_mapping.values.flatten << 'signer' << 'signer-entire-authority')
      end
      it 'returns all the roles when the signer has the column `ALLRNA` set to 0' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        column_hash['ALLRNA'] = -1
        column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'N'
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to match_array(role_mapping.values.flatten << 'signer-manager' << 'signer')
      end
      it 'returns the role `signer-etransact` if the column `ACTIVE_TOKEN_EXISTS_FLAG` is set to `Y`' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'Y'
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to include('signer-etransact')
      end
      it 'returns the role `signer` if the user exists in the SIGNERS table at all' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to match_array(['signer'])
      end
      it 'does not include the role `signer` if the user was not found' do
        allow(roles_cursor).to receive(:fetch_hash)
        expect(json).to match_array([])
      end
    end
  end

end