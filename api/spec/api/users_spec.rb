require 'spec_helper'

describe MAPI::ServiceApp do
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
      it 'executes the `signer_id_query`' do
        query = double('Signer ID Query')
        allow(MAPI::Services::Users).to receive(:signer_id_query).with(username).and_return(query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(query)
        make_request
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
      it 'returns all the roles except `signer-manager` and `signer-wiretransfers` when the signer has the column `ALLPRODUCT` set to -1' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        column_hash['ALLPRODUCT'] = -1
        column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'N'
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to match_array((role_mapping.values.flatten << 'signer' << 'signer-entire-authority') - role_mapping['WIRESIGNER'] )
      end
      it 'returns all the roles except `signer-wiretransfers` when the signer has the column `ALLRNA` set to 0' do
        column_hash = Hash[role_mapping.keys.collect {|key| [key, 0]}]
        column_hash['ALLRNA'] = -1
        column_hash['ACTIVE_TOKEN_EXISTS_FLAG'] = 'N'
        allow(roles_cursor).to receive(:fetch_hash).and_yield(column_hash)
        expect(json).to match_array((role_mapping.values.flatten << 'signer-manager' << 'signer') - role_mapping['WIRESIGNER'])
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

  describe '`signer_id_query` class method' do
    let(:username) { SecureRandom.hex.upcase }
    let(:call_method) { MAPI::Services::Users.signer_id_query(username) }

    it 'generates a SELECT statement' do
      expect(call_method).to match(/\A\s*SELECT\s+SIGNER_ID\s+FROM\s+WEB_ADM.ETRANSACT_SIGNER\s+/i)
    end
    it 'quotes the downcased `username`' do
      expect(MAPI::Services::Users).to receive(:quote).with(username.downcase)
      call_method
    end
    it 'includes the quoted `username`' do
      quoted_username = SecureRandom.hex
      allow(MAPI::Services::Users).to receive(:quote).with(username.downcase).and_return(quoted_username)
      expect(call_method).to match(/\s+WHERE\s+LOWER\(LOGIN_ID\)\s+=\s+#{quoted_username}\s*\z/m)
    end
  end

end