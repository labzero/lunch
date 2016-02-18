require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'member parallel_shift_analysis' do
    describe 'the `parallel_shift_analysis` endpoint' do
      let(:parallel_shift_data) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'parallel_shift_data.json'))) }
      let(:parallel_shift) { MAPI::Services::Member::ParallelShiftAnalysis.parallel_shift(subject, member_id) }
      let(:max_date) { [Date.new(2015,1,31)] }

      it 'calls the `parallel_shift` method when the endpoint is hit' do
        allow(MAPI::Services::Member::ParallelShiftAnalysis).to receive(:parallel_shift).and_return('a response')
        get "/member/#{member_id}/parallel_shift_analysis"
        expect(last_response.status).to eq(200)
      end

      [:test, :production].each do |env|
        describe "in the #{env} environment" do
          if env == :production
            let(:parallel_shift_result_set) {double('Oracle Result Set', fetch_hash: nil, fetch: nil)}
            let(:parallel_shift_result) {[parallel_shift_data[0],parallel_shift_data[1], parallel_shift_data[2], parallel_shift_data[3], parallel_shift_data[4], parallel_shift_data[5], parallel_shift_data[6], nil]}

            before do
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(parallel_shift_result_set)
              allow(parallel_shift_result_set).to receive(:fetch).and_return(max_date)
              allow(parallel_shift_result_set).to receive(:fetch_hash).and_return(*parallel_shift_result)
            end
            it 'returns nil if `max_date` is nil' do
              allow(parallel_shift_result_set).to receive(:fetch).and_return(nil)
              expect(parallel_shift).to be_nil
            end
            it 'returns an empty array for the `putable_advances` attribute if the SQL query returns nothing' do
              allow(parallel_shift_result_set).to receive(:fetch_hash).and_return(nil)
              expect(parallel_shift[:putable_advances]).to eq([])
            end
          end
          it "returns an object with an `as_of_date` attribute" do
            expect(parallel_shift[:as_of_date]).to be_kind_of(Date)
          end
          it "returns an object with a `putable_advances` attribute" do
            expect(parallel_shift[:putable_advances]).to be_kind_of(Array)
          end
          describe 'the `putable_advances` array' do
            it 'contains objects with an `advance_number`' do
              parallel_shift[:putable_advances].each do |advance|
                expect(advance[:advance_number]).to be_kind_of(String)
              end
            end
            it 'contains objects with an `issue_date`' do
              parallel_shift[:putable_advances].each do |advance|
                expect(advance[:issue_date]).to be_kind_of(Date)
              end
            end
            it 'contains objects with a `interest_rate`' do
              parallel_shift[:putable_advances].each do |advance|
                expect(advance[:interest_rate]).to be_kind_of(Float)
              end
            end
            %w(shift_neg_300 shift_neg_200 shift_neg_100 shift_0 shift_100 shift_200 shift_300).each do |key|
              it "contains objects with a `#{key}` attribute" do
                parallel_shift[:putable_advances].each do |advance|
                  expect(advance.keys).to include(key.to_sym)
                  expect(advance[key.to_sym]).to be_kind_of(Float) if advance[key.to_sym]
                end
              end
            end
          end
        end
      end
    end
  end
end
