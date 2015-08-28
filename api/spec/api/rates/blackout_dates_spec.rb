require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::BlackoutDates do
  subject{ MAPI::Services::Rates::BlackoutDates }
  let(:logger) { double( 'logger' ) }
  describe 'blackout_dates' do
    describe 'production' do
      describe 'blackout_dates_production' do
        let(:cursor) { double('Blackout Dates Cursor')}
        let(:day1){ double( 'day1' ) }
        let(:day2){ double( 'day2' ) }
        let(:day3){ double( 'day3' ) }
        let(:logger) { double( 'logger' ) }

        it 'executes the SQL query for blackout dates query' do
          allow(ActiveRecord::Base.connection).to receive(:execute).with(MAPI::Services::Rates::BlackoutDates::SQL).and_return(cursor)
          allow(cursor).to receive(:fetch).and_return( [day1], [day2], [day3], nil)
          expect( subject.blackout_dates_production(logger)).to be == [day1, day2, day3]
        end

        it 'logs an error for exceptions' do
          allow(ActiveRecord::Base.connection).to receive(:execute).with(MAPI::Services::Rates::BlackoutDates::SQL).and_return(cursor)
          allow(cursor).to receive(:fetch).and_raise( :exception )
          expect( logger ).to receive(:error)
          subject.blackout_dates_production(logger)
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
      describe 'fake_data_fixed' do
        it 'should return a list of Date' do
          subject.fake_data_fixed.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end

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
    end
  end
end