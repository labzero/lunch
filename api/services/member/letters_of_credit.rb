module MAPI
  module Services
    module Member
      module LettersOfCredit
        def self.letters_of_credit(app, member_id)
          if app.settings.environment == :production
            credits_query = <<-SQL
              SELECT FHLB_ID,
              LC_LC_NUMBER,
              LCX_CURRENT_PAR,
              LCX_TRANS_SPREAD,
              LC_TRADE_DATE,
              LC_SETTLEMENT_DATE,
              LC_MATURITY_DATE,
              LC_ISSUE_NUMBER ,
              LCX_UPDATE_DATE
              FROM web_inet.WEB_LC_LATESTDATE_RPT
              WHERE FHLB_ID = #{ ActiveRecord::Base.connection.quote(member_id)}
            SQL
            credits_cursor = ActiveRecord::Base.connection.execute(credits_query)
            credits = []
            while row = credits_cursor.fetch_hash()
              credits << row.with_indifferent_access unless row['LCX_UPDATE_DATE'].blank?
            end
            return {as_of_date: nil, total_current_par: nil, credits: []} if credits.blank?
            as_of_date = credits.first[:LCX_UPDATE_DATE]

            total_current_par = credits.inject(0) {|sum, credit| sum + credit[:LCX_CURRENT_PAR].to_i}

            {
              as_of_date: (as_of_date.to_date if as_of_date),
              total_current_par: total_current_par,
              credits: Private.format_credits(credits)
            }
          else
            letters_of_credit = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'letters_of_credit.json'))).with_indifferent_access
            letters_of_credit[:as_of_date] = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
            letters_of_credit
          end
        end
        # private
        module Private
          def self.format_credits(credits)
            credits.collect do |credit|
              {
                lc_number: (credit[:LC_LC_NUMBER].to_s if credit[:LC_LC_NUMBER]),
                current_par: (credit[:LCX_CURRENT_PAR].to_i if credit[:LCX_CURRENT_PAR]),
                maintenance_charge: (credit[:LCX_TRANS_SPREAD].to_i if credit[:LCX_TRANS_SPREAD]),
                trade_date: (credit[:LC_TRADE_DATE].to_date if credit[:LC_TRADE_DATE]),
                settlement_date: (credit[:LC_SETTLEMENT_DATE].to_date if credit[:LC_SETTLEMENT_DATE]),
                maturity_date: (credit[:LC_MATURITY_DATE].to_date if credit[:LC_MATURITY_DATE]),
                description: (credit[:LC_ISSUE_NUMBER].to_s if credit[:LC_ISSUE_NUMBER])
              }
            end
          end
        end
      end
    end
  end
end
