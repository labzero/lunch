module MAPI
  module Services
    module Member
      module SecuritiesTransactions
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        SECURITIES_FIELD_MAPPINGS = {
            'fhlb_id'                => 'fhlb_id',
            'cur_btc_account_number' => 'custody_account_no',
            'cur_new_trans'          => 'new_transaction',
            'cur_cusip'              => 'cusip',
            'cur_trans_code'         => 'transaction_code',
            'cur_desc_line_1'        => 'security_description',
            'cur_units'              => 'units',
            'cur_maturity_date'      => 'maturity_date',
            'cur_principal_amount'   => 'payment_or_principal',
            'cur_interest_amount'    => 'interest',
            'cur_total_amount'       => 'total',
        }

        XMAS_2015  = Date.parse('2015-12-25')
        DEC_1_2015 = Date.parse('2015-12-01')

        def self.final_securities_count_sql(fhlb_id, rundate)
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
          h = Hash[hash.map{ |k,v| [mapping[k],v]}].with_indifferent_access
          h[:new_transaction] = h[:new_transaction]=='Y'
          h
        end

        def self.fetch_final_securities_count(environment, logger, fhlb_id, rundate)
          if environment == :production
            fetch_hashes(logger, final_securities_count_sql(fhlb_id, rundate))
          else
            rundate == XMAS_2015 || rundate == DEC_1_2015 ? [{ 'RECORDSCOUNT' => 0 }] : fake('securities_count')
          end
        end

        def self.fetch_securities_transactions(environment, logger, fhlb_id, rundate, final)
          if environment == :production
            fetch_hashes(logger, securities_transactions_sql(fhlb_id, rundate, final), {to_date: ['CUR_MATURITY_DATE'], to_i: ["CUR_UNITS"], to_f: %w(CUR_PRINCIPAL_AMOUNT CUR_INTEREST_AMOUNT CUR_TOTAL_AMOUNT)}, true)
          else
            rundate == XMAS_2015 ? [] : fake('securities_transactions')
          end
        end

        def self.securities_transactions(app, fhlb_id, rundate)
          final      = fetch_final_securities_count(app.settings.environment, app.logger, fhlb_id, rundate).first['RECORDSCOUNT'] > 0
          originals  = fetch_securities_transactions(app.settings.environment, app.logger, fhlb_id, rundate, final)
          translated = originals.map{ |h| translate_securities_transactions_fields(h) }
          result     = { final: final, transactions: translated }
          result.merge!( previous_business_day: previous_business_day(app, rundate) ) if translated.empty?
          result
        end

        def self.previous_business_day(app, date)
          holidays = MAPI::Services::Rates::Holidays.holidays(app, date-1.week, date-1.day)
          MAPI::Services::Rates.find_next_business_day(date-1.day, -1.day, holidays)
        end
      end
    end
  end
end
