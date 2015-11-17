require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe '`quick_advance_flag` method' do
    let(:quick_advance_flag) { MAPI::Services::Member::Flags.quick_advance_flag(subject, MEMBER_ID) }
    let(:quick_advance_flag_data) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'quick_advance_flag.json')))
    }
    let(:quick_advance_flag) { MAPI::Services::Member::Flags.quick_advance_flag(subject, MEMBER_ID) }

    it 'calls the `quick_advance_flag` method when the endpoint is hit' do
      allow(MAPI::Services::Member::Flags).to receive(:quick_advance_flag).and_return('a response')
      get "/member/#{MEMBER_ID}/quick_advance_flag"
      expect(last_response.status).to eq(200)
    end

    [:test, :production].each do |env|
      describe "in the #{env} environment" do
        let(:quick_advance_flag_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:quick_advance_flag_result) {[quick_advance_flag_data[0], nil]} if env == :production

        before do
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(quick_advance_flag_result_set)
            allow(quick_advance_flag_result_set).to receive(:fetch).and_return(*quick_advance_flag_result)
          end
        end
        it 'returns an array containing a single string' do
          expect(quick_advance_flag.first).to be_kind_of(String)
        end
      end
    end

    it 'returns [\'N\'] for member_id 13 in the test environment' do
      expect(MAPI::Services::Member::Flags.quick_advance_flag(subject, 13)).to eq(['N'])
    end
  end
end
