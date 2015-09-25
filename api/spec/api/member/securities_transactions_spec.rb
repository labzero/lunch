require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750
  DATE = Time.zone.parse( '20 sept 2015').to_date.iso8601

  #subject { MAPI::Services::Member::SecuritiesTransactions }

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'Securities Transactions' do
    let(:securities_transactions) { get "/member/#{MEMBER_ID}/securities_transactions/#{DATE}"; JSON.parse(last_response.body) }
    let(:fhlb_id)              { double('fhlb_id')              }
    let(:custody_account_no)   { double('custody_account_no')   }
    let(:new_transaction)      { double('new_transaction')      }
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
          'cur_new_trans'          => new_transaction,
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
    let(:after_hash) do
      {
          fhlb_id:              fhlb_id,
          custody_account_no:   custody_account_no,
          new_transaction:      new_transaction,
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
    let(:before_hash_upper) { Hash[before_hash.map{ |k,v| [k.upcase,v]}] }

    it 'should return expected advances detail hash where value could not be nil' do
      securities_transactions['transactions'].each do |row|
        expect(row['fhlb_id']).to              be_kind_of(Numeric)
        expect(row['custody_account_no']).to   be_kind_of(String)
        expect(row['new_transaction']).to      be_kind_of(String)
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
    describe 'securities_transactions_production' do
      let(:logger) { double('logger')  }
      let(:fhlb_id){ double('fhlb_id') }
      let(:rundate){ double('rundate') }
      let(:count_sql){ double('count_sql') }
      let(:transactions_sql){ double('transactions_sql') }

      before do
        allow(MAPI::Services::Member::SecuritiesTransactions).to receive(:securities_count_sql).with(fhlb_id,rundate).and_return( count_sql )
        allow(MAPI::Services::Member::SecuritiesTransactions).to receive(:securities_transactions_sql).and_return( transactions_sql )
        allow(MAPI::Services::Member::SecuritiesTransactions).to receive(:fetch_hashes).with(logger, count_sql).and_return([{'RECORDSCOUNT' => 1}])
        allow(MAPI::Services::Member::SecuritiesTransactions).to receive(:fetch_hashes).with(logger, transactions_sql).and_return([before_hash])
      end

      it 'should return a valid result' do
        expect(MAPI::Services::Member::SecuritiesTransactions::securities_transactions_production(logger, fhlb_id, rundate)).to eq({ final: true, transactions: [after_hash]})
      end
    end

    describe 'translate_fields' do

      it 'should map fields appropriately for lower case keys' do
        expect(MAPI::Services::Member::SecuritiesTransactions::translate_fields(before_hash)).to eq(after_hash)
      end

      it 'should map fields appropriately for upper case keys' do
        expect(MAPI::Services::Member::SecuritiesTransactions::translate_fields(before_hash_upper)).to eq(after_hash)
      end
    end
  end
end
