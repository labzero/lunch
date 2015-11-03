module MAPI
  module Services
    module Member
      module CapitalStockTrialBalance
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        def self.business_date_sql(date)
          <<-SQL
          select portfolios.cdb_utility.PRIOR_BUSINESS_DAY(#{quote(date)} + 1) as business_date from dual
          SQL
        end

        def self.closing_balance_sql(fhlb_id, business_date)
          <<-SQL
          select fhlb_id,
                 sum(no_share_holding) as number_of_shares,
                 count(*) number_of_certificates
          from capstock.capstock_shareholding
          where fhlb_id = #{quote(fhlb_id)}
          and (sold_date is null or sold_date > #{quote(business_date)})
          and purchase_date <= #{quote(business_date)}
          and no_share_holding > 0
          group by fhlb_id
          SQL
        end

        def self.certificates_sql(fhlb_id, business_date)
          <<-SQL
          select cert_id as certificate_sequence,
                 class,
                 issue_date,
                 no_share_holding as shares_outstanding,
                 tran_type as transaction_type
          from capstock.capstock_trial_balance_web_v
          where fhlb_id = #{quote(fhlb_id)}
          and (sold_date is null or sold_date > #{quote(business_date)}
          and issue_date <= #{quote(business_date)}
          and purchase_date <= #{quote(business_date)}
          SQL
        end

        def self.capital_stock_trial_balance(app, fhlb_id, date)
          if app.settings.environment == :production
            business_date   = fetch_hashes(app.logger, business_date_sql(date)).first['business_date']
            closing_balance = fetch_hashes(app.logger, closing_balance_sql(fhlb_id, business_date))
            certificates    = fetch_hashes(app.logger, certificates_sql(fhlb_id, business_date))
          else
            closing_balance = fake('capital_stock_trial_balance_closing_balance')
            certificates    = fake('capital_stock_trial_balance_certificates')
          end
          closing_balance.first.merge("certificates" => certificates)
        end
      end
    end
  end
end
