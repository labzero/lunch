require 'rails_helper'

describe FinancialInstrumentHelper, type: :helper do
  describe '`financial_instrument_standardize` method' do
    it 'converts string with WL at the end to Wholeloan' do
      expect(helper.financial_instrument_standardize('Some Text WL')).to eq('Some Text Wholeloan')
    end
    it 'ignores conversion if the WL string is not at the end of the input' do
      expect(helper.financial_instrument_standardize('Some WL Text')).to eq('Some WL Text')
    end
  end

  describe '`interest_rate_precision_by_advance_type` method' do
    let(:advance_type) { SecureRandom.hex }
    let(:interest_rate) { double('interest rate') }
    let(:call_method) { helper.interest_rate_precision_by_advance_type(interest_rate, advance_type)}
    before { allow(helper).to receive(:determine_precision_to_n).and_return(rand(0..7)) }

    it 'determines the precision of the interest rate out to 7 decimal places' do
      expect(helper).to receive(:determine_precision_to_n).with(interest_rate, 7)
      call_method
    end

    describe 'determining if the advance has an ARC advance type' do
      shared_examples 'it matches the regular expression' do
        it 'returns 5' do
          expect(call_method).to be 5
        end
        it 'returns 5 even if the results of `determine_precision_to_n` indicate a lesser precision' do
          allow(helper).to receive(:determine_precision_to_n).and_return(rand(0..4))
          expect(call_method).to be 5
        end
      end

      shared_examples 'it does not match the regular expression' do
        context 'when the interest rate has more than 5 decimal places' do
          before { allow(helper).to receive(:determine_precision_to_n).and_return(rand(6..9)) }
          it 'returns 5' do
            expect(call_method).to be 5
          end
        end

        context 'when the interest rate has more than 2 decimal places but less than 6' do
          let(:decimal_places) { rand(3..5) }
          it 'returns the result of `determine_precision_to_n`' do
            allow(helper).to receive(:determine_precision_to_n).and_return(decimal_places)
            expect(call_method).to be decimal_places
          end
        end

        context 'when the interest rate has less than 3 decimal places' do
          before { allow(helper).to receive(:determine_precision_to_n).and_return(rand(0..2)) }
          it 'returns 2' do
            expect(call_method).to be 2
          end
        end
      end
      context 'when the advance type is a kind of ARC advance' do
        ['arc', 'ARC', 'SBC-ARC-LIBOR', 'aRc-15-year', 'arc-libor', 'arc/libor', 'libor_arc'].each do |type|
          describe "when the advance type is `#{type}`" do
            let(:advance_type) { type }
            it_behaves_like 'it matches the regular expression'
          end
        end
      end
      context 'when the advance type is not a kind of ARC advance' do
        ['marc', 'ARCHERY', 'SBC-VRC-LIBOR', 'vrc', 'sbc', 'frc', 'frc-libor'].each do |type|
          describe "when the advance type is `#{type}`" do
            let(:advance_type) { type }
            it_behaves_like 'it does not match the regular expression'
          end
        end
      end
    end
  end

  describe '`determine_precision_to_n` method' do
    it 'returns the precision of the given float' do
      {
        1.34254 => 5,
        0.0009 => 4,
        4 => 0,
        0.64738473 => 8,
        0.00003000 => 5,
        3.14 => 2
      }.each do |float, precision|
        expect(helper.determine_precision_to_n(float, 10)).to eq(precision)
      end
    end
    it 'handles floats passed as strings' do
      {
        '1.342543' => 6,
        '0.000917' => 6,
        '4' => 0,
        '0.64738473' => 8,
        '0.00003000' => 5,
        '3.142' => 3
      }.each do |float, precision|
        expect(helper.determine_precision_to_n(float, 10)).to eq(precision)
      end
    end
    it 'returns the precision argument if the actual precision of the float is greater than the requested precision' do
      {
        1.34254 => 4,
        0.0009 => 4,
        4 => 0,
        0.64738473 => 4,
        0.00003000 => 0,
        3.14 => 2
      }.each do |float, precision|
        expect(helper.determine_precision_to_n(float, 4)).to eq(precision)
      end
    end
  end
end