require 'spec_helper'



describe MAPI::ServiceApp do
  describe 'class method `authentication_block`' do
    let(:rack_env) {{'rack.input' => 'foo', 'QUERY_STRING' => ''}}
    it "returns a Proc" do
      expect(MAPI::ServiceApp.authentication_block).to be_kind_of(Proc)
      expect(MAPI::ServiceApp.authentication_block.arity).to eq(3)
    end
    it "returns true if the passed token matches ENV['MAPI_SECRET_TOKEN']" do
      expect(MAPI::ServiceApp.authentication_block.call(ENV['MAPI_SECRET_TOKEN'], {}, {})).to eq(true)
    end
    describe "the passed token doesn't match ENV['MAPI_SECRET_TOKEN']" do
      it "returns false if there is no `api_key` parameter" do
        expect(MAPI::ServiceApp.authentication_block.call('foo', {}, rack_env)).to eq(false)
      end
      it "returns false if the query string parameter `api_key` doesn't match ENV['MAPI_SECRET_TOKEN']" do
        rack_env['QUERY_STRING'] = "api_key=foo"
        expect(MAPI::ServiceApp.authentication_block.call('foo', {}, rack_env)).to eq(false)
      end
      it "returns true if the query string parameter `api_key` matches ENV['MAPI_SECRET_TOKEN']" do
        rack_env['QUERY_STRING'] = "api_key=#{ENV['MAPI_SECRET_TOKEN']}"
        expect(MAPI::ServiceApp.authentication_block.call('foo', {}, rack_env)).to eq(true)
      end
      it "replaces the `api_key` value with [SANITIZED] if present" do
        rack_env['QUERY_STRING'] = 'api_key=foo'
        MAPI::ServiceApp.authentication_block.call('foo', {}, rack_env)
        expect(rack_env['QUERY_STRING']).to eq('api_key=[SANITIZED]')
      end
    end
  end
end