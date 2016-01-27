require 'spec_helper'

describe MAPI::ServiceApp do
  let(:a_date) { Time.zone.parse( '20 sept 2015').to_date.iso8601 }

  subject { MAPI::Services::Member::SecuritiesTransactions }

  describe 'Securities Transactions' do
    let(:fhlb_id)              { double('fhlb_id')              }
    let(:custody_account_no)   { double('custody_account_no')   }
    let(:cusip)                { double('cusip')                }
    let(:transaction_code)     { double('transaction_code')     }
    let(:security_description) { double('security_description') }
    let(:units)                { double('units')                }
    let(:maturity_date)        { double('maturity_date')        }
    let(:payment_or_principal) { double('payment_or_principal') }
    let(:interest)             { double('interest')             }
    let(:total)                { double('total')                }
    let(:before_hash) do
      {
          'fhlb_id'                => fhlb_id,
          'cur_btc_account_number' => custody_account_no,
          'cur_new_trans'          => 'Y',
          'cur_cusip'              => cusip,
          'cur_trans_code'         => transaction_code,
          'cur_desc_line1'         => security_description,
          'cur_units'              => units,
          'cur_maturity_date'      => maturity_date,
          'cur_principal_amount'   => payment_or_principal,
          'cur_interest_amount'    => interest,
          'cur_total_amount'       => total
      }
    end
    let(:fhlb_id2)              { double('fhlb_id2')              }
    let(:custody_account_no2)   { double('custody_account_no2')   }
    let(:cusip2)                { double('cusip2')                }
    let(:transaction_code2)     { double('transaction_code2')     }
    let(:security_description2) { double('security_description2') }
    let(:units2)                { double('units2')                }
    let(:maturity_date2)        { double('maturity_date2')        }
    let(:payment_or_principal2) { double('payment_or_principal2') }
    let(:interest2)             { double('interest2')             }
    let(:total2)                { double('total2')                }
    let(:before_hash2) do
      {
          'fhlb_id'                => fhlb_id2,
          'cur_btc_account_number' => custody_account_no2,
          'cur_new_trans'          => 'N',
          'cur_cusip'              => cusip2,
          'cur_trans_code'         => transaction_code2,
          'cur_desc_line1'         => security_description2,
          'cur_units'              => units2,
          'cur_maturity_date'      => maturity_date2,
          'cur_principal_amount'   => payment_or_principal2,
          'cur_interest_amount'    => interest2,
          'cur_total_amount'       => total2
      }
    end
    let(:after_hash) do
      {
          fhlb_id:              fhlb_id,
          custody_account_no:   custody_account_no,
          new_transaction:      true,
          cusip:                cusip,
          transaction_code:     transaction_code,
          security_description: security_description,
          units:                units,
          maturity_date:        maturity_date,
          payment_or_principal: payment_or_principal,
          interest:             interest,
          total:                total
      }.with_indifferent_access
    end
    let(:after_hash2) do
        {
            fhlb_id:              fhlb_id2,
            custody_account_no:   custody_account_no2,
            new_transaction:      false,
            cusip:                cusip2,
            transaction_code:     transaction_code2,
            security_description: security_description2,
            units:                units2,
            maturity_date:        maturity_date2,
            payment_or_principal: payment_or_principal2,
            interest:             interest2,
            total:                total2
        }.with_indifferent_access
    end
    let(:before_hash_upper) { Hash[before_hash.map{ |k,v| [k.upcase,v]}] }

    [:test, :development].each do |env|
      describe "#{env}" do
        let(:securities_transactions) { get "/member/#{member_id}/securities_transactions/#{a_date}"; JSON.parse(last_response.body) }
        it 'should return expected advances detail hash where value could not be nil' do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env)
          securities_transactions['transactions'].each do |row|
            expect(row['fhlb_id']).to              be_kind_of(Numeric)
            expect(row['custody_account_no']).to   be_kind_of(String)
            expect(row['new_transaction']).to      be_boolean
            expect(row['cusip']).to                be_kind_of(String)
            expect(row['transaction_code']).to     be_kind_of(String)
            expect(row['security_description']).to be_kind_of(String)
            expect(row['units']).to                be_kind_of(Numeric)
            expect(row['maturity_date']).to        be_kind_of(String)
            expect(row['payment_or_principal']).to be_kind_of(Numeric)
            expect(row['interest']).to             be_kind_of(Numeric)
            expect(row['total']).to                be_kind_of(Numeric)
          end
        end
      end
    end

    describe 'securities_transactions_production' do
      let(:logger) { double('logger')  }
      let(:fhlb_id){ double('fhlb_id') }
      let(:rundate){ double('rundate') }
      let(:count_sql){ double('count_sql') }
      let(:transactions_sql){ double('transactions_sql') }

      before do
        allow(subject).to receive(:securities_count_sql).with(fhlb_id,rundate).and_return( count_sql )
        allow(subject).to receive(:securities_transactions_sql).and_return( transactions_sql )
        allow(subject).to receive(:fetch_hashes).with(logger, count_sql).and_return([{'RECORDSCOUNT' => 1}])
        allow(subject).to receive(:fetch_hashes).with(logger, transactions_sql).and_return([before_hash,before_hash2])
      end

      it 'should return a valid result' do
        expect(subject.securities_transactions_production(logger, fhlb_id, rundate)).to eq({ final: true, transactions: [after_hash,after_hash2]})
      end

      it 'should return a valid result for non-final' do
        allow(subject).to receive(:fetch_hashes).with(logger, count_sql).and_return([{'RECORDSCOUNT' => 0}])
        expect(subject.securities_transactions_production(logger, fhlb_id, rundate)).to eq({ final: false, transactions: [after_hash,after_hash2]})
      end
    end

    describe 'translate_securities_transactions_fields' do
      it 'should map fields appropriately for lower case keys' do
        expect(subject.translate_securities_transactions_fields(before_hash)).to eq(after_hash)
      end

      it 'should map fields appropriately for upper case keys' do
        expect(subject.translate_securities_transactions_fields(before_hash_upper)).to eq(after_hash)
      end
    end
  end
end
