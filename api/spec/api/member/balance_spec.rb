require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'member balance pledged collateral' do
    collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
    let(:pledged_collateral) { get "/member/#{member_id}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(Numeric)
      end
    end
    describe 'in the production environment' do
      let(:some_values) {[300, 400, 500]}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set).to receive(:fetch).and_return(10, nil)
        allow(result_set2).to receive(:fetch).and_return(some_values, nil)
      end
      it 'should return json with keys mortgages, agency, aaa, aa' do
        expect(pledged_collateral.length).to be >= 1
        collateral_types.each do |collateral_type|
          expect(pledged_collateral[collateral_type]).to be_kind_of(Numeric)
        end
      end
      it 'should not return the second row found' do
        expect(result_set).to receive(:fetch).and_return([1000], [20], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([2000, 3000, 40000], some_values,  nil).at_least(1).times
        expect(pledged_collateral['mortgages']).to eq(1000)
        expect(pledged_collateral['agency']).to eq(2000)
        expect(pledged_collateral['aaa']).to eq(3000)
        expect(pledged_collateral['aa']).to eq(40000)
      end
      it 'should return zeros if no record was found' do
        allow(result_set).to receive(:fetch).and_return(nil)
        allow(result_set2).to receive(:fetch).and_return(nil)
        expect(pledged_collateral['mortgages']).to eq(0)
        expect(pledged_collateral['agency']).to eq(0)
        expect(pledged_collateral['aaa']).to eq(0)
        expect(pledged_collateral['aa']).to eq(0)
      end
    end
  end

  describe 'member balance total securities' do
    let(:total_securities) { get "/member/#{member_id}/balance/total_securities"; JSON.parse(last_response.body) }
    it "should return json with keys pledge_securities, safekept_securities" do
      expect(total_securities.length).to be >= 1
      expect(total_securities['pledged_securities']).to be_kind_of(Numeric)
      expect(total_securities['safekept_securities']).to be_kind_of(Numeric)
    end
    describe 'in the production environment' do
      let!(:some_activity) {[12345, 54911, 99999]}
      let(:result_set1) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set1).to receive(:fetch).and_return(some_activity, nil)
        allow(result_set2).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return jason wth keys pledged_securities, safekept_securities with the first column for each of the execute fetch returned' do
        expect(total_securities['pledged_securities']).to eq(12345)
        expect(total_securities['safekept_securities']).to eq(12345)
      end
      it 'should return zeros if no record was found' do
        allow(result_set1).to receive(:fetch).and_return(nil)
        allow(result_set2).to receive(:fetch).and_return(nil)
        expect(total_securities['safekept_securities']).to eq(0)
        expect(total_securities['pledged_securities']).to eq(0)
      end
    end
  end

  describe 'member balance effective borrowing capacity' do
    let(:effective_borrowing_capacity) { get "/member/#{member_id}/balance/effective_borrowing_capacity"; JSON.parse(last_response.body) }
    it "should return json with keys total_capacity, unused_capacity" do
      expect(effective_borrowing_capacity.length).to be >= 1
      effective_borrowing_capacity_type = ['total_capacity', 'unused_capacity']
      effective_borrowing_capacity_type.each do |effective_borrowing_capacity_type|
        expect(effective_borrowing_capacity[effective_borrowing_capacity_type]).to be_kind_of(Numeric)
      end
    end
    describe 'in the production environment' do
      let!(:some_activity) {[12345, 54911, 99999]}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return json wth keys total_capacity, unused_capacity with the first 2 columns returned' do
        expect(effective_borrowing_capacity['total_capacity']).to eq(12345)
        expect(effective_borrowing_capacity['unused_capacity']).to eq(54911)
      end
      it 'should return zeros if no record was found' do
        allow(result_set).to receive(:fetch).and_return(nil)
        expect(effective_borrowing_capacity['total_capacity']).to eq(0)
        expect(effective_borrowing_capacity['unused_capacity']).to eq(0)
      end
    end
  end
end