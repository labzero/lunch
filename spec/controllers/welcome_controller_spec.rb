require 'rails_helper'

RSpec.describe WelcomeController, :type => :controller do
  let(:revision) { SecureRandom.hex }

  it { should use_around_filter(:skip_timeout_reset) }
  it { should_not use_before_action(:authenticate_user!) }
  it { should_not use_before_action(:check_terms) }
  
  describe "GET details" do
    let(:make_request) { get :details }
    it_behaves_like 'a user not required action', :get, :details
    it 'calls `get_revision`' do
      expect(subject).to receive(:get_revision)
      make_request
    end
    it 'renders the revision as text' do
      allow(subject).to receive(:get_revision).and_return(revision)
      make_request
      expect(response.body).to eq(revision)
    end
    it 'renders an error if no revision is found' do
      allow(subject).to receive(:get_revision).and_return(false)
      make_request
      expect(response.body).to eq('No REVISION found!')
    end
  end

  describe 'GET healthy' do
    let(:make_request) { get :healthy; JSON.parse(response.body) }
    it_behaves_like 'a user not required action', :get, :healthy
    it 'returns a JSON hash' do
      expect(make_request).to be_kind_of(Hash)
    end
    it 'returns the revision found via `get_revision`' do
      allow(subject).to receive(:get_revision).and_return(revision)
      expect(make_request['revision']).to eq(revision)
    end
    describe 'Redis status' do
      let(:service_key) {'tomorrowmorrowland'}
      it 'returns `true` if Redis responds to a PING' do
        allow(Resque.redis).to receive(:ping).and_return('PONG')
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if Redis fails to respond to a PING' do
        allow(Resque.redis).to receive(:ping).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the Redis ping raises an error' do
        allow(Resque.redis).to receive(:ping).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end

    describe 'DB status' do
      let(:service_key) {'beforetimes'}
      it 'returns `true` if the DB connection is active' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the DB connection is not active' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the DB connection active check raises an error' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end

    describe 'MAPI status' do
      let(:service_key) {'bartertown'}
      it 'returns the MAPI status' do
        status = SecureRandom.hex
        allow_any_instance_of(MAPIService).to receive(:ping).and_return(status)
        expect(make_request[service_key]).to eq(status)
      end
      it 'returns `false` if the MAPI ping raises an error' do
        allow_any_instance_of(MAPIService).to receive(:ping).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end

    describe 'Resque status' do
      let(:service_key) {'masterblaster'}
      let(:workers) {[]}
      before do
        allow(Resque).to receive(:workers).and_return(workers)
      end
      it 'returns `true` if there are workers in the Resque pool' do
        allow(Resque.workers).to receive(:count).and_return(1)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if there are no workers in the Resque pool' do
        allow(Resque.workers).to receive(:count).and_return(0)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the Resque pool worker check raises an error' do
        allow(Resque.workers).to receive(:count).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
      it 'calls `prune_dead_workers` on each worker before checking the count' do
        a_worker = double('Worker')
        expect(a_worker).to receive(:prune_dead_workers).ordered
        allow(workers).to receive(:each).and_yield(a_worker)
        expect(Resque.workers).to receive(:count).ordered
        make_request
      end
    end

    describe 'LDAP Intranet status' do
      let(:service_key) {'madmax'}
      let(:connection) { double(Devise::LDAP::Connection) }
      let(:raw_connection) { double(Net::LDAP, search: nil) }
      before do
        allow(connection).to receive(:open).and_yield(raw_connection)
        allow(Devise::LDAP::Connection).to receive(:admin).with('intranet').and_return(connection)
      end
      it 'returns `true` if the search returns something' do
        allow(raw_connection).to receive(:search).and_return([{}])
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the search returns nothing' do
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the search raises an error' do
        allow(raw_connection).to receive(:search).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end

    describe 'LDAP Extranet status' do
      let(:service_key) {'roadwarrior'}
      let(:connection) { double(Devise::LDAP::Connection) }
      let(:raw_connection) { double(Net::LDAP, search: nil) }
      before do
        allow(connection).to receive(:open).and_yield(raw_connection)
        allow(Devise::LDAP::Connection).to receive(:admin).with('extranet').and_return(connection)
      end
      it 'returns `true` if the search returns something' do
        allow(raw_connection).to receive(:search).and_return([{}])
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the search returns nothing' do
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the search raises an error' do
        allow(raw_connection).to receive(:search).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end
  end

  describe "GET session_status" do
    let(:response_body) { get :session_status; JSON.parse(response.body).with_indifferent_access }
    let(:request_env) { double('request environment', :[] => nil, :'[]=' => nil) }
    let(:path) { double('logged out path') }
    before do
      allow(controller).to receive(:user_signed_in?)
    end
    it_behaves_like 'a user not required action', :get, :session_status

    # Check to see that `devise.skip_trackable` config is turned off before the request, then turned back on afterwards
    it 'should skip resetting the session timer in Devise' do
      allow(request.env).to receive(:'[]=').and_call_original
      expect(request.env).to receive(:'[]=').with('devise.skip_trackable', false)
      expect(request.env).to receive(:'[]=').with('devise.skip_trackable', true)
      get :session_status
    end
    it 'should return a JSON hash with `logged_out_path` set to the `after_sign_out_path_for(nil)` if there is a current user' do
      allow(controller).to receive(:after_sign_out_path_for).with(nil).and_return(path)
      expect(response_body[:logged_out_path]).to eq(JSON.parse(path.to_json))
    end
    it 'should return a JSON hash with `user_signed_in` set to true if the user is signed in' do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      expect(response_body[:user_signed_in]).to eq(true)
    end
    it 'should return a JSON hash with `user_signed_in` set to false if the user is not signed in' do
      allow(controller).to receive(:user_signed_in?).and_return(false)
      expect(response_body[:user_signed_in]).to eq(false)
    end
  end

  describe '`get_revision` method' do
    let(:call_method) { subject.send(:get_revision) }
    describe 'without a REVISION file' do
      before { `rm ./REVISION 2>/dev/null` }
      it 'should return false' do
        expect(call_method).to eq(false)
      end
    end
    describe 'with a REVISION file' do
      before { `echo '#{revision}' > ./REVISION` }
      after { `rm ./REVISION 2>/dev/null` }
      it 'should return the contents' do
        expect(call_method).to eq(revision)
      end
    end
  end
end
