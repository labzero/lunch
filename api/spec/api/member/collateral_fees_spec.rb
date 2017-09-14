require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'MAPI::Services::Member::CollateralFees' do
    collateral_fees_module = MAPI::Services::Member::CollateralFees
    let(:app) { instance_double(MAPI::ServiceApp, logger: double('logger', error: nil)) }
    let(:today) { Time.zone.today }
    let(:member_id) { rand(1000..9999) }
    let(:quoted_member_id) { SecureRandom.hex }

    before { allow(Time.zone).to receive(:today).and_return(today) }

    describe 'class methods' do
      describe 'available_statements' do
        let(:call_method) { collateral_fees_module.available_statements(app, member_id) }
        it 'calls `should_fake?` with the app' do
          expect(collateral_fees_module).to receive(:should_fake?).with(app).and_return(true)
          call_method
        end
        context 'when `should_fake?` returns false' do
          before do
            allow(collateral_fees_module).to receive(:should_fake?).with(app).and_return(false)
            allow(collateral_fees_module).to receive(:fetch_rows)
            allow(collateral_fees_module).to receive(:quote)
          end
          it 'calls `fetch_rows` with the logger from the app' do
            expect(collateral_fees_module).to receive(:fetch_rows).with(app.logger, anything)
            call_method
          end
          it 'quotes the `member_id` param' do
            expect(collateral_fees_module).to receive(:quote).with(member_id)
            call_method
          end
          describe 'the SQL passed to `fetch_rows`' do
            it 'selects the `ACTIVITY_DATE` field that has been transformed to the `YYYY-MM-DD` character date format' do
              matcher = Regexp.new(/\A\s*SELECT.*\s+TO_CHAR\s*\(\s*ACTIVITY_DATE\s*,\s*'YYYY-MM-DD'\s*\)(?:,|\s+)/im)
              expect(collateral_fees_module).to receive(:fetch_rows).with(anything, matcher).and_return([])
              call_method
            end
            it 'selects from `FEE_CHARGE@COLAPROD_LINK.WORLD`' do
              matcher = Regexp.new(/\A\s*SELECT.+FROM\s+FEE_CHARGE@COLAPROD_LINK.WORLD/im)
              expect(collateral_fees_module).to receive(:fetch_rows).with(anything, matcher).and_return([])
              call_method
            end
            it 'selects the rows WHERE the `CUSTOMER_MASTER_ID` is equal to the quoted `member_id`' do
              allow(collateral_fees_module).to receive(:quote).with(member_id).and_return(quoted_member_id)
              matcher = Regexp.new(/\A\s*SELECT.+FROM.+WHERE\s+CUSTOMER_MASTER_ID\s*=\s*#{quoted_member_id}/im)
              expect(collateral_fees_module).to receive(:fetch_rows).with(anything, matcher).and_return([])
              call_method
            end
          end
          describe 'processing the results of `fetch_rows`' do
            it 'returns a flattened array' do
              results = [[SecureRandom.hex], [SecureRandom.hex + 'a'], [[SecureRandom.hex + 'z']]]
              allow(collateral_fees_module).to receive(:fetch_rows).and_return(results)
              expect(call_method).to eq(results.flatten)
            end
            it 'only returns unique values' do
              a = SecureRandom.hex
              b = a + 'z'
              results = [a, b, a, a]
              allow(collateral_fees_module).to receive(:fetch_rows).and_return(results)
              expect(call_method).to eq([a, b])
            end
            it 'returns nil if `fetch_rows` returns nil' do
              allow(collateral_fees_module).to receive(:fetch_rows).and_return(nil)
              expect(call_method).to be nil
            end
          end
        end
        context 'when `should_fake?` returns true' do
          before { allow(collateral_fees_module).to receive(:should_fake?).and_return(true) }
          it 'returns an array of 20 iso8601 strings' do
            results = call_method
            expect(results.length).to eq(20)
            results.each do |result|
              expect(result.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)).not_to be nil
            end
          end
          it 'has a first member that is the iso8601 representation of last month end' do
            expect(call_method.first).to eq((today - 1.month).end_of_month.iso8601)
          end
          it 'has a last member that is the iso8601 representation of month end from 20 months ago' do
            expect(call_method.last).to eq((today - 20.months).end_of_month.iso8601)
          end
        end
      end

      describe '`collateral_fees`' do
        let(:date) { double('some date') }
        let(:call_method) { collateral_fees_module.collateral_fees(app, member_id, date) }
        before do
          allow(collateral_fees_module).to receive(:should_fake?).with(app).and_return(true)
          allow(collateral_fees_module).to receive(:fake_collateral_fees).and_return([])
        end

        it 'calls `should_fake?` with the app' do
          expect(collateral_fees_module).to receive(:should_fake?).with(app).and_return(true)
          call_method
        end
        context 'when `should_fake?` returns false' do
          before do
            allow(collateral_fees_module).to receive(:should_fake?).and_return(false)
            allow(collateral_fees_module).to receive(:fetch_hashes).and_return([])
            allow(collateral_fees_module).to receive(:quote)
          end

          it 'calls `fetch_hashes` with the logger from the app' do
            expect(collateral_fees_module).to receive(:fetch_hashes).with(app.logger, any_args)
            call_method
          end
          it 'calls `fetch_hashes` with an empty hash for the mapping arg' do
            expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, anything, {}, anything)
            call_method
          end
          it 'calls `fetch_hashes` with the downcase arg set to true' do
            expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, anything, anything, true)
            call_method
          end
          it 'quotes the `member_id` param' do
            expect(collateral_fees_module).to receive(:quote).with(member_id)
            call_method
          end
          it 'quotes the `date` param' do
            expect(collateral_fees_module).to receive(:quote).with(date)
            call_method
          end
          describe 'the SQL passed to `fetch_hashes`' do
            let(:quoted_date) { SecureRandom.hex }
            describe 'the selected fields' do
              ['SERVICE_TYPE', 'CHARGE_AMOUNT', 'CHARGE_QUANTITY', 'CHARGE_RATE'].each do |field|
                it "selects the `#{field}` field" do
                  matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(?:,|\s+)/im)
                  expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, matcher, any_args).and_return([])
                  call_method
                end
              end
            end
            it 'selects from `FEE_CHARGE@COLAPROD_LINK.WORLD`' do
              matcher = Regexp.new(/\A\s*SELECT.+FROM\s+FEE_CHARGE@COLAPROD_LINK.WORLD/im)
              expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, matcher, any_args).and_return([])
              call_method
            end
            it 'selects the rows WHERE the `CUSTOMER_MASTER_ID` is equal to the quoted `member_id`' do
              allow(collateral_fees_module).to receive(:quote).with(member_id).and_return(quoted_member_id)
              matcher = Regexp.new(/\A\s*SELECT.+FROM.+WHERE\s+CUSTOMER_MASTER_ID\s*=\s*#{quoted_member_id}/im)
              expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, matcher, any_args).and_return([])
              call_method
            end
            it 'selects rows WHERE the truncated ACTIVITY_DATE is equal to the datified-quoted `date` param' do
              allow(collateral_fees_module).to receive(:quote).with(date).and_return(quoted_date)
              matcher = Regexp.new(/\A\s*SELECT.+FROM.+WHERE.+TRUNC\s*\(\s*ACTIVITY_DATE\s*\)\s*=\s*TO_DATE\s*\(\s*#{quoted_date}\s*,\s*'YYYY-MM-DD'\s*\)/im)
              expect(collateral_fees_module).to receive(:fetch_hashes).with(anything, matcher, any_args).and_return([])
              call_method
            end
          end
          it 'raises an error if `fetch_hashes` returns nil' do
            allow(collateral_fees_module).to receive(:fetch_hashes).and_return(nil)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to fetch collateral fees')
          end
        end
        context 'when `should_fake?` returns true' do
          before do
            allow(collateral_fees_module).to receive(:should_fake?).and_return(true)
            allow(collateral_fees_module).to receive(:fake_collateral_fees).and_return([])
          end

          it 'calls `fake_collateral_fees` with the `member_id`' do
            expect(collateral_fees_module).to receive(:fake_collateral_fees).with(member_id, anything).and_return([])
            call_method
          end
          it 'calls `fake_collateral_fees` with the `date`' do
            expect(collateral_fees_module).to receive(:fake_collateral_fees).with(anything, date).and_return([])
            call_method
          end
        end
        describe 'constructing the hash of collateral fees' do
          let(:raw_collateral_fees) {[
            {
              'service_type' => 'Release',
              'charge_quantity' => rand(1..99),
              'charge_rate' => rand(1..99) + rand,
              'charge_amount' => rand(1..99) + rand
            },
            {
              'service_type' => 'Custody Fee',
              'charge_quantity' => rand(1..99),
              'charge_rate' => rand(1..99) + rand,
              'charge_amount' => rand(1..99) + rand
            },
            {
              'service_type' => 'Review',
              'charge_quantity' => rand(1..99),
              'charge_rate' => rand(1..99) + rand,
              'charge_amount' => rand(1..99) + rand
            },
            {
              'service_type' => 'Processing',
              'charge_quantity' => rand(1..99),
              'charge_rate' => rand(1..99) + rand,
              'charge_amount' => rand(1..99) + rand
            }
          ]}

          before { allow(collateral_fees_module).to receive(:fake_collateral_fees).and_return(raw_collateral_fees) }

          describe 'the returned hash' do
            collateral_fees_module::COLLATERAL_FEE_MAPPING.each do |fee_type, service_type|
              describe "the `#{fee_type}` values" do
                let(:raw_hash) { raw_collateral_fees.select { |hash| hash['service_type'] == service_type }.first }
                it "contains a `count` that is the `charge_quantity` of the collateral fee row with `service_type` of `#{service_type}`" do
                  expect(call_method[fee_type][:count]).to eq(raw_hash['charge_quantity'])
                end
                it "contains a `cost` that is the `charge_rate` of the collateral fee row with `service_type` of `#{service_type}`" do
                  expect(call_method[fee_type][:cost]).to eq(raw_hash['charge_rate'])
                end
                it "contains a `total` that is the `charge_amount` of the collateral fee row with `service_type` of `#{service_type}`" do
                  expect(call_method[fee_type][:total]).to eq(raw_hash['charge_amount'])
                end
              end
            end
          end
        end
      end

      describe '`fake_collateral_fees`' do
        let(:call_method) { collateral_fees_module.fake_collateral_fees(member_id, today) }

        collateral_fees_module::COLLATERAL_FEE_MAPPING.each do |fee_type, service_type|
          it "returns an array which includes a hash with a `service_type` equal to `#{service_type}`" do
            expect(call_method.select { |hash| hash['service_type'] == service_type }.first).not_to be nil
          end
          describe "the `#{fee_type}` hash in the returned array" do
            let(:raw_hash) { call_method.select { |hash| hash['service_type'] == service_type }.first }

            it 'has a `charge_quantity` that is a number between 0 and 999' do
              expect(raw_hash['charge_quantity']).to be_between(0,999)
            end
            it 'has a `charge_rate` that is set to `0.3`, `2.5`, or `3`' do
              expect([0.3, 2.5, 3]).to include(raw_hash['charge_rate'])
            end
            it 'has a `charge_amount` that is equal to the `charge_quantity` times the `charge_rate`, rounded to 2 decimal places' do
              expect(raw_hash['charge_amount']).to eq((raw_hash['charge_quantity'] * raw_hash['charge_rate']).round(2))
            end
          end
        end
      end
    end
  end
end