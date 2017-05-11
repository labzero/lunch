require 'spec_helper'

describe MAPI::Services::Rates::RateBands do
  subject { MAPI::Services::Rates::RateBands }
  let(:app) { double(MAPI::ServiceApp, logger: logger) }
  let(:logger) { double('logger') }

  describe '`get_terms` class method' do
    let(:frequency) { SecureRandom.hex }
    let(:unit) { SecureRandom.hex }
    let(:rate_band) { {'FOBO_TERM_FREQUENCY' => frequency, 'FOBO_TERM_UNIT' => unit} }
    let(:call_method) { subject.get_terms(rate_band) }

    it 'returns the terms from `FREQUENCY_MAPPING` for the rate band' do
      terms = instance_double(Array, 'An Array of Terms')
      stub_const("#{described_class}::FREQUENCY_MAPPING", {"#{frequency}#{unit}" => terms})
      expect(call_method).to be(terms)
    end
    it 'returns an empty array if terms can\'t be found' do
      stub_const("#{described_class}::FREQUENCY_MAPPING", {})
      expect(call_method).to eq([])
    end
  end

  describe 'rate bands' do
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

  describe '`update_rate_bands`' do
    let(:term) { subject::TERM_MAPPING.keys.sample }
    let(:rate_bands) {{term => double('rate band info')}}
    let(:call_method) { subject.update_rate_bands(app, rate_bands) }
    before { allow(subject).to receive(:should_fake?).and_return(true) }

    context 'when `should_fake?` returns true' do
      it 'returns true' do
        expect(call_method).to be true
      end
    end
    context 'when `should_fake?` returns false' do
      before { allow(subject).to receive(:should_fake?).and_return(false) }

      it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
        expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
        call_method
      end
      it 'returns true if the transaction block executes without error' do
        allow(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
        expect(call_method).to be true
      end
      describe 'the transaction block' do
        let(:set_clause) { SecureRandom.hex }
        before do
          allow(ActiveRecord::Base).to receive(:transaction).and_yield
          allow(subject).to receive(:build_update_rate_band_set_clause).and_return(set_clause)
          allow(subject).to receive(:quote)
          allow(subject).to receive(:execute_sql).and_return(true)
        end

        it 'calls `build_update_rate_band_set_clause` with the rate band info' do
          expect(subject).to receive(:build_update_rate_band_set_clause).with(rate_bands[term]).and_return(set_clause)
          call_method
        end
        it 'raises an `MAPI::Shared::Errors::SQLError` if `execute_sql` does not succeed' do
          allow(subject).to receive(:execute_sql).and_return(false)
          expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to update rate band with term: #{term}")
        end
        it 'calls `execute_sql` with the logger' do
          expect(subject).to receive(:execute_sql).with(logger, anything).and_return(true)
          call_method
        end
        describe 'the update_rate_band_sql' do
          it 'updates the `WEB_ADM.AO_RATE_BANDS` table' do
            matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_RATE_BANDS\s+/im)
            expect(subject).to receive(:execute_sql).with(anything, matcher).and_return(true)
            call_method
          end
          it 'has a SET clause that consists of the result of `build_update_rate_band_set_clause`' do
            matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_RATE_BANDS\s+.*SET\s+#{set_clause}\s+/im)
            expect(subject).to receive(:execute_sql).with(anything, matcher).and_return(true)
            call_method
          end
          it 'calls `quote` on the `frequency_unit` from the mapped term' do
            expect(subject).to receive(:quote).with(subject::TERM_MAPPING[term][:frequency_unit])
            call_method
          end
          it 'calls `quote` on the `frequency` from the mapped term' do
            expect(subject).to receive(:quote).with(subject::TERM_MAPPING[term][:frequency])
            call_method
          end
          describe 'the WHERE clause' do
            it 'performs the update on the row where the `FOBO_TERM_UNIT` equals the quoted `frequency_unit`' do
              quoted_frequency_unit = SecureRandom.hex
              allow(subject).to receive(:quote).with(subject::TERM_MAPPING[term][:frequency_unit]).and_return(quoted_frequency_unit)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_RATE_BANDS\s+.*SET\s+.+WHERE\s+.*FOBO_TERM_UNIT\s+=\s+#{quoted_frequency_unit}.*\z/im)
              expect(subject).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'performs the update on the row where the `FOBO_TERM_FREQUENCY` equals the quoted `frequency`' do
              quoted_frequency = SecureRandom.hex
              allow(subject).to receive(:quote).with(subject::TERM_MAPPING[term][:frequency]).and_return(quoted_frequency)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_RATE_BANDS\s+.*SET\s+.+WHERE\s+.*FOBO_TERM_FREQUENCY\s+=\s+#{quoted_frequency}.*\z/im)
              expect(subject).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
        end
        it 'updates as many rows as there are terms in the rate band hash it is passed' do
          rate_band_hash = {}
          subject::TERM_MAPPING.keys.each do |field|
            rate_band_hash[field] = SecureRandom.hex
          end
          expect(subject).to receive(:execute_sql).exactly(rate_band_hash.keys.count).times.and_return(true)
          subject.update_rate_bands(app, rate_band_hash)
        end
      end
    end
  end

  describe '`build_update_rate_band_set_clause`' do
    let(:valid_field) { subject::VALID_RATE_BAND_UPDATE_FIELDS.sample }
    let(:string_field_name) { double('string field name', upcase: valid_field) }
    let(:field) { double('field name', to_s: string_field_name) }
    let(:integer_value) { instance_double(Integer) }
    let(:value) { double('some value', to_i: nil) }
    let(:rate_band_info) { {field => value} }
    let(:call_method) { subject.build_update_rate_band_set_clause(rate_band_info) }

    it 'converts the bucket field name to a string' do
      expect(field).to receive(:to_s).and_return(string_field_name)
      call_method
    end
    it 'upcases the string version of the field name' do
      expect(string_field_name).to receive(:upcase).and_return(valid_field)
      call_method
    end
    it 'raises a `MAPI::Shared::Errors::InvalidFieldError` if the field name is not in the list of valid fields' do
      invalid_field_name = SecureRandom.hex
      allow(string_field_name).to receive(:upcase).and_return(invalid_field_name)
      expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{invalid_field_name} is an invalid field")
    end
    it 'calls `to_i` on the value' do
      expect(value).to receive(:to_i)
      call_method
    end
    it 'calls `quote` with the value as an integer' do
      allow(value).to receive(:to_i).and_return(integer_value)
      expect(subject).to receive(:quote).with(integer_value)
      call_method
    end
    it 'includes the key and quoted value in its returned string' do
      quoted_value = SecureRandom.hex
      allow(subject).to receive(:quote).and_return(quoted_value)
      matcher = Regexp.new(/(\A|\s+)#{valid_field}\s+=\s+#{quoted_value}(\s+|\z)/)
      expect(call_method).to match(matcher)
    end
    it 'joins all key-value strings together into a single string with `, `' do
      rate_band_hash = {}
      subject::VALID_RATE_BAND_UPDATE_FIELDS.each do |field|
        rate_band_hash[field] = SecureRandom.hex
      end
      expect(subject.build_update_rate_band_set_clause(rate_band_hash).scan(/, /).count).to eq(subject::VALID_RATE_BAND_UPDATE_FIELDS.count - 1)
    end
  end
end