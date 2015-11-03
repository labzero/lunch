module MAPI
  module Services
    module Member
      module SecuritiesTransactions
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        SECURITIES_FIELD_MAPPINGS = {
            'fhlb_id'                =>'fhlb_id',
            'cur_btc_account_number' => 'custody_account_no',
            'cur_new_trans'          => 'new_transaction',
            'cur_cusip'              => 'cusip',
            'cur_trans_code'         => 'transaction_code',
            'cur_desc_line1'         => 'security_description',
            'cur_units'              => 'units',
            'cur_maturity_date'      => 'maturity_date',
            'cur_principal_amount'   => 'payment_or_principal',
            'cur_interest_amount'    => 'interest',
            'cur_total_amount'       => 'total',
        }

        def self.securities_count_sql(fhlb_id, rundate)
          <<-SQL
          SELECT COUNT(*) AS RECORDSCOUNT FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.CURRENT_DAY, SAFEKEEPING.CUSTOMER_PROFILE CP
          WHERE CP.CP_ID = ADX.CP_ID AND CUR_BTC_ACCOUNT_NUMBER = RTRIM(ADX_BTC_ACCOUNT_NUMBER)
          AND CUR_BTC_DATE = #{quote(rundate)} AND FHLB_ID = #{quote(fhlb_id)}  AND CUR_FILE_TYPE = 'PM'
          SQL
        end

        def self.securities_transactions_sql(fhlb_id, rundate, final)
          <<-SQL
          SELECT cp.FHLB_ID, cd.CUR_BTC_ACCOUNT_NUMBER, cd.CUR_NEW_TRANS, cd.CUR_CUSIP, cd.CUR_TRANS_CODE, cd.CUR_DESC_LINE_1,
                 cd.CUR_UNITS, cd.CUR_MATURITY_DATE, cd.CUR_PRINCIPAL_AMOUNT, cd.CUR_INTEREST_AMOUNT, cd.CUR_TOTAL_AMOUNT
          FROM SAFEKEEPING.account_docket_xref dx,  SAFEKEEPING.current_day cd, SAFEKEEPING.customer_profile cp, web_adm.web_member_data wmd
          WHERE cp.CP_ID = dx.CP_ID AND cp.fhlb_id = #{quote(fhlb_id)} AND cp.fhlb_id = wmd.fhlb_id AND
                RTRIM(cd.cur_btc_account_number) = RTRIM(dx.adx_btc_account_number) AND
                cd.cur_btc_date = #{quote(rundate)} AND cd.cur_file_type = #{quote(final ? 'PM' : 'AM')}
          ORDER BY cd.CUR_DEBIT_CREDIT_IND,dx.ADX_BTC_ACCOUNT_NUMBER ASC, cd.CUR_CUSIP ASC
          SQL
        end

        def self.translate_securities_transactions_fields(hash, mapping=SECURITIES_FIELD_MAPPINGS)
          h = Hash[hash.map{ |k,v| [mapping[k.downcase],v]}].with_indifferent_access
          h[:new_transaction] = h[:new_transaction]=='Y'
          h
        end

        def self.securities_transactions(environment, logger, fhlb_id, rundate)
          if environment == :production
            securities_transactions_production(logger, fhlb_id, rundate)
          else
            securities_transactions_development(fhlb_id, rundate)
          end
        end

        def self.securities_transactions_production(logger, fhlb_id, rundate)
          final      = fetch_hashes(logger, securities_count_sql(fhlb_id, rundate)).first['RECORDSCOUNT'] > 0
          originals  = fetch_hashes(logger, securities_transactions_sql(fhlb_id, rundate, final))
          translated = originals.map{ |h| translate_securities_transactions_fields(h) }
          { final: final, transactions: translated }
        end

        def self.securities_transactions_development(_fhlb_id, _rundate)
          fake_hash('securities_transactions')
        end
      end
    end
  end
end
