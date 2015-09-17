require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::BlackoutDates do
  subject{ MAPI::Services::Rates::BlackoutDates }
  describe 'blackout_dates' do
    let(:logger){ double( 'logger' ) }
    describe 'production' do
      describe 'blackout_dates_production' do
        let(:day1){ double('day1') }
        let(:day2){ double('day2') }
        let(:day3){ double('day3') }
        it 'executes the SQL query for blackout dates query' do
          allow(subject).to receive(:fetch_objects).with(logger, MAPI::Services::Rates::BlackoutDates::SQL).and_return([day1, day2, day3])
          expect( subject.blackout_dates_production(logger)).to be == [day1, day2, day3]
        end
      end
    end

    describe 'blackout_dates' do
      it 'should call blackout_dates_production if environment is production' do
        expect(subject).to receive(:blackout_dates_production)
        subject.blackout_dates(logger, :production)
      end

      it 'should call blackout_dates_developemnt if environment is not production' do
        expect(subject).to receive(:blackout_dates_development)
        subject.blackout_dates(logger, :development)
      end
    end

    describe 'development' do

      describe 'fake_data_relative_to_today' do
        it 'should return a list of Date' do
          subject.fake_data_relative_to_today.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end

      describe 'blackout_dates_development' do
        it 'should return a list of Date' do
          subject.blackout_dates_development.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end

      describe 'nearest_business_day' do
        let (:fri){ double('friday',   saturday?: false, sunday?: false ) }
        let (:sat){ double('saturday', saturday?: true,  sunday?: false) }
        let (:sun){ double('sunday',   saturday?: false, sunday?: true) }
        let (:mon){ double('monday',   saturday?: false, sunday?: false) }
        it 'should return argument if it is a business day' do
          expect(subject.nearest_business_day(fri)).to be == fri
        end
        it 'should return different day if argument is not a business day' do
          allow(sat).to receive(:+).with(1.day).and_return(sun)
          allow(sun).to receive(:+).with(1.day).and_return(mon)
          expect(subject.nearest_business_day(sat)).to be == mon
        end
      end
    end
  end
end