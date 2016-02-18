require 'spec_helper'

describe MAPI::ServiceApp do
  describe '`quick_advance_flag` method' do
    let(:quick_advance_flag) { MAPI::Services::Member::Flags.quick_advance_flag(subject, member_id) }

    it 'calls the `quick_advance_flag` method when the endpoint is hit' do
      allow(MAPI::Services::Member::Flags).to receive(:quick_advance_flag).and_return('a response')
      get "/member/#{member_id}/quick_advance_flag"
      expect(last_response.status).to eq(200)
    end

    describe 'in the :production environment' do
      let(:quick_advance_flag_result_set) {double('Oracle Result Set', fetch: nil)}

      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(quick_advance_flag_result_set)
      end

      it 'returns true for the `quick_advance_enabled` value if the SQL query returns `[\'Y\']`' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return(['Y', nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(true)
      end
      it 'returns false for the `quick_advance_enabled` value if the SQL query returns `[\'N\']`' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return(['N', nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
      end
      it 'returns false for the `quick_advance_enabled` value if the SQL query returns nil' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return([nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
      end
    end

    [:development, :test].each do |env|
      describe "in the #{env} environment" do
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(:env)
        end
        describe 'when the member id is not 13' do
          let(:member_id) { ([*1..10000] - [13]).sample }
          it 'returns true for the `quick_advance_enabled` value ' do
            expect(quick_advance_flag[:quick_advance_enabled]).to eq(true)
          end
        end
        describe 'when the member id is 13' do
          let(:member_id) { 13 }
          it 'returns false for the `quick_advance_enabled` value ' do
            expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
          end
        end
      end
    end
  end
end
