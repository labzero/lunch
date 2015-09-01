require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  describe 'blackout_dates' do
    describe 'production' do
      describe 'blackout_dates_production' do
        let(:date_cursor) { double('Blackout Dates Cursor')}
        let(:tomorrow){ Time.zone.today + 1.day }
        let(:next_week){ Time.zone.today + 1.week }
        let(:next_month){ Time.zone.today + 1.month }
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        end
        it 'executes the SQL query for blackout dates query' do
          allow(ActiveRecord::Base.connection).to receive(:execute).with(MAPI::Services::Rates::BlackoutDates::SQL).and_return(date_cursor)
          allow(date_cursor).to receive(:fetch).and_return( [tomorrow], [next_week], [next_month], nil)
          expect( MAPI::Services::Rates::BlackoutDates::blackout_dates_production).to be == [tomorrow, next_week, next_month]
        end
      end
    end

    describe 'development' do
      describe 'fake_data_fixed' do
        it 'should return a list of Date' do
          MAPI::Services::Rates::BlackoutDates::fake_data_fixed.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end
      describe 'fake_data_relative_to_today' do
        it 'should return a list of Date' do
          MAPI::Services::Rates::BlackoutDates::fake_data_relative_to_today.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end
      describe 'blackout_dates_development' do
        it 'should return a list of Date' do
          MAPI::Services::Rates::BlackoutDates::blackout_dates_development.each do |date|
            expect(date).to be_instance_of Date
          end
        end
      end
    end
  end
end