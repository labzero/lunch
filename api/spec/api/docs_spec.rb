require 'spec_helper'

describe MAPI::DocApp do
  describe 'GET /' do
    before do
      get '/'
    end
    it 'responds with a 302' do
      expect(last_response.status).to be(302)
    end
    it 'has a new location of `/index.html`' do
      expect(last_response.headers["Location"]).to match(/\/index\.html\z/)
    end
  end

  describe 'GET /apidocs' do
    let(:models) { instance_double(Array, 'Array of Swagger Models') }
    let(:make_request) { get '/apidocs' }
    before do
      stub_const('SWAGGER_CLASSES', models)
      allow(Swagger::Blocks).to receive(:build_root_json)
    end
    it 'calls `Swagger::Blocks.build_root_json`' do
      expect(Swagger::Blocks).to receive(:build_root_json).with(models)
      make_request
    end
    it 'responds with the JSON representation of the swagger root' do
      json = SecureRandom.hex
      allow(Swagger::Blocks).to receive(:build_root_json).and_return(double('Swagger Docs', to_json: json))
      make_request
      expect(last_response.body).to eq(json)
    end
  end

  describe 'GET /apidocs/:id' do
    let(:models) { instance_double(Array, 'Array of Swagger Models') }
    let(:id) { SecureRandom.hex }
    let(:make_request) { get "/apidocs/#{id}" }
    before do
      stub_const('SWAGGER_CLASSES', models)
      allow(Swagger::Blocks).to receive(:build_api_json)
    end
    it 'calls `Swagger::Blocks.build_api_json` with the ID' do
      expect(Swagger::Blocks).to receive(:build_api_json).with(id, anything)
      make_request
    end
    it 'calls `Swagger::Blocks.build_api_json` with the SWAGGER_CLASSES' do
      expect(Swagger::Blocks).to receive(:build_api_json).with(anything, models)
      make_request
    end
    it 'responds with the JSON representation of the swagger class' do
      json = SecureRandom.hex
      allow(Swagger::Blocks).to receive(:build_api_json).and_return(double('Swagger Docs', to_json: json))
      make_request
      expect(last_response.body).to eq(json)
    end
  end
end