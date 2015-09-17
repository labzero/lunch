require 'spec_helper'

describe MAPI::Services::Rates::RateBands do
  subject { MAPI::Services::Rates::RateBands }
  let(:logger) { double('logger') }


  describe 'rate bands' do
    it 'should call rate_bands_production if environment is production' do
      allow(subject).to receive(:rate_bands_production).and_return([])
      expect(subject.rate_bands(logger, :production)).to be == {}
    end

    it 'should call rate_bands_development if environment is development' do
      allow(subject).to receive(:rate_bands_development).and_return([])
      expect(subject.rate_bands(logger, :development)).to be == {}
    end

    it 'should call rate_bands_development if environment is test' do
      allow(subject).to receive(:rate_bands_development).and_return([])
      expect(subject.rate_bands(logger, :test)).to be == {}
    end
  end

  let(:day1) { double('day1') }
  let(:day2) { double('day2') }
  let(:day3) { double('day3') }
  let(:term1) { double('term1') }
  let(:term2) { double('term2') }
  let(:term3) { double('term3') }
  let(:term4) { double('term4') }
  before do
    allow(subject).to receive(:get_terms).with(day1).and_return([term1])
    allow(subject).to receive(:get_terms).with(day2).and_return([term2,term4])
    allow(subject).to receive(:get_terms).with(day3).and_return([term3])
  end

  describe 'production' do
    describe 'rate_bands' do
      it 'returns nil if fetch_hashes returns nil' do
        allow(subject).to receive(:fetch_hashes).with(logger, subject::SQL).and_return(nil)
        expect(subject.rate_bands(logger, :production)).to be == nil
      end

      it 'executes the SQL query for rate bands query' do
        allow(subject).to receive(:fetch_hashes).with(logger, subject::SQL).and_return([day1, day2, day3])
        expect(subject.rate_bands(logger, :production)).to be == {term1 => day1, term2 => day2, term3 => day3, term4 => day2}
      end
    end
  end

  %w(test development).each do |environment|
    describe environment do
      describe 'rate_bands' do
        it 'should parse some JSON' do
          allow(JSON).to receive(:parse).and_return([day1, day2, day3])
          expect(subject.rate_bands(logger, environment.to_sym)).to be == {term1 => day1, term2 => day2, term3 => day3, term4 => day2}
        end
      end
    end
  end
end