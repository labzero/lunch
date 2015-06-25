require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member forward_commitments' do
    let(:advances) do
      new_array = []
      advances = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'advances.json')))
      advances.each do |advance|
        advance[:ADVDET_CURRENT_PAR] = rand(0..1000000)
        new_array << advance.with_indifferent_access
      end
      new_array
    end
    let(:total_current_par) { advances.inject(0) {|sum, advance| sum + advance[:ADVDET_CURRENT_PAR]} }
    let(:member_forward_commitments) { MAPI::Services::Member::ForwardCommitments.forward_commitments(subject, MEMBER_ID) }
    let(:formatted_advances) { double('an array of advances') }

    it 'calls the `forward_commitments` method when the endpoint is hit' do
      allow(MAPI::Services::Member::ForwardCommitments).to receive(:forward_commitments).and_return('a response')
      get "/member/#{MEMBER_ID}/forward_commitments"
      expect(last_response.status).to eq(200)
    end

    [:test, :production].each do |env|
      describe "`forward_commitments` method in the #{env} environment" do
        let(:advances_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:advances_result) {[advances[0], advances[1], advances[2], nil]} if env == :production

        before do
          allow(MAPI::Services::Member::ForwardCommitments::Private).to receive(:fake_advances).and_return(advances)
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(advances_result_set)
            allow(advances_result_set).to receive(:fetch_hash).and_return(*advances_result)
          end
        end
        if env == :production
          describe 'when the database returns no advances' do
            before { allow(advances_result_set).to receive(:fetch_hash).and_return(nil) }
            it 'returns nil for the `as_of_date`' do
              expect(member_forward_commitments[:as_of_date]).to be_nil
            end
            it 'returns nil for the `total_current_par`' do
              expect(member_forward_commitments[:total_current_par]).to be_nil
            end
            it 'returns an empty array for `advances`' do
              expect(member_forward_commitments[:advances]).to eq([])
            end
          end
        end
        it 'returns an object with an `as_of_date`' do
          expect(member_forward_commitments[:as_of_date]).to be_kind_of(Date)
        end
        it "returns an object with a `total_current_par` that is the sum of the individual advance's ADVDET_CURRENT_PAR" do
          expect(member_forward_commitments[:total_current_par]).to eq(total_current_par)
        end
        it 'returns an object with an array of formatted `advances`' do
          allow(MAPI::Services::Member::ForwardCommitments::Private).to receive(:format_advances).with(advances).and_return(formatted_advances)
          expect(member_forward_commitments[:advances]).to eq(formatted_advances)
        end
      end
    end

    describe 'private methods' do
      describe '`format_advances` method' do
        let(:formatted_advances) { MAPI::Services::Member::ForwardCommitments::Private.format_advances(advances) }
    
        [:maturity_date, :funding_date, :trade_date].each do |property|
          it "returns an object with a `#{property}` formatted as a date" do
            formatted_advances.each do |advance|
              expect(advance[property]).to be_kind_of(Date)
            end
          end
        end
        [:advance_number, :advance_type].each do |property|
          it "returns an object with a `#{property}` formatted as a string" do
            formatted_advances.each do |advance|
              expect(advance[property]).to be_kind_of(String)
            end
          end
        end
        it 'returns an object with a `current_par` formatted as an integer' do
          formatted_advances.each do |advance|
            expect(advance[:current_par]).to be_kind_of(Integer)
          end
        end
        it 'returns an object with an `interest_rate` formatted as a float' do
          formatted_advances.each do |advance|
            expect(advance[:interest_rate]).to be_kind_of(Float)
          end
        end
        describe 'handling nil values' do
          [:maturity_date, :funding_date, :trade_date, :advance_number, :advance_type, :current_par, :interest_rate].each do |property|
            it "returns an object with a nil value for `#{property}` if that property doesn't have a value" do
              MAPI::Services::Member::ForwardCommitments::Private.format_advances([{}, {}]).each do |security|
                expect(security[property]).to be_nil
              end
            end
          end
        end
      end
      
      describe '`fake_advances` method' do
        let(:fake_advances) { MAPI::Services::Member::ForwardCommitments::Private.fake_advances(MEMBER_ID, Time.zone.now.to_date) }
      
        it 'returns an array of fake advance objects with the appropriate keys' do
          fake_advances.each do |advance|
            %i(ADVDET_TRADE_DATE ADVDET_SETTLEMENT_DATE ADVDET_MATURITY_DATE ADVDET_ADVANCE_NUMBER ADVDET_MNEMONIC ADVDET_CURRENT_PAR ADVDET_INTEREST_RATE).each do |property|
              expect(advance[property]).to_not be_nil
            end
          end
        end
      end
    end
  end
end
