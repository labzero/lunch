require 'spec_helper'

describe MAPI::Services::Rates::RateBands do
  subject { MAPI::Services::Rates::RateBands }
  let(:logger) { double('logger') }


  describe 'rate bands' do
    it 'should call rate_bands_production if environment is production' do
      allow(subject).to receive(:rate_bands_production).and_return([])
      expect(subject.rate_bands(logger, :production)).to be == {}
    end

    it 'should call rate_bands_development if environment is not production' do
      allow(subject).to receive(:rate_bands_development).and_return([])
      expect(subject.rate_bands(logger, :development)).to be == {}
    end
  end

  describe 'production' do
    describe 'rate_bands_production' do
      let(:day1) { double('day1') }
      let(:day2) { double('day2') }
      let(:day3) { double('day3') }

      it 'returns nil if fetch_hashes returns nil' do
        allow(subject).to receive(:fetch_hashes).with(logger, subject::SQL).and_return(nil)
        expect(subject.rate_bands_production(logger)).to be == nil
      end

      it 'executes the SQL query for rate bands query' do
        allow(subject).to receive(:fetch_hashes).with(logger, subject::SQL).and_return([day1, day2, day3])
        expect(subject.rate_bands_production(logger)).to be == [day1, day2, day3]
      end
    end
  end

  describe 'development' do
    describe 'rate_bands_development' do
      let(:json) { double('json', with_indifferent_access: hash) }
      let(:hash) { double('json') }
      it 'should parse some JSON' do
        allow(JSON).to receive(:parse).and_return(json)
        expect(subject.rate_bands_development).to be == hash
      end
    end
  end
end