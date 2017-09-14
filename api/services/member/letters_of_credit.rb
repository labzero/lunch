module MAPI
  module Services
    module Member
      module LettersOfCredit
        include MAPI::Shared::Utils
        def self.letters_of_credit(app, member_id)
          unless should_fake?(app)
            credits_query = <<-SQL
              SELECT FHLB_ID,
              LC_LC_NUMBER,
              LC_SORT_CODE,
              LCX_CURRENT_PAR,
              LCX_TRANS_SPREAD,
              LC_TRADE_DATE,
              LC_SETTLEMENT_DATE,
              LC_MATURITY_DATE,
              LC_ISSUE_NUMBER,
              LCX_UPDATE_DATE,
              LC_BENEFICIARY
              FROM WEB_INET.WEB_LC_LATESTDATE_RPT
              WHERE FHLB_ID = #{ quote(member_id)}
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

        def self.letter_of_credit(app, member_id, lc_number)
          unless should_fake?(app)
            loc_query = <<-SQL
              SELECT FHLB_ID,
              LC_LC_NUMBER,
              LC_SORT_CODE,
              LCX_CURRENT_PAR,
              LCX_TRANS_SPREAD,
              LC_TRADE_DATE,
              LC_SETTLEMENT_DATE,
              LC_MATURITY_DATE,
              LC_ISSUE_NUMBER,
              LCX_UPDATE_DATE,
              LC_BENEFICIARY
              FROM WEB_INET.WEB_LC_LATESTDATE_RPT
              WHERE LC_LC_NUMBER = #{ quote(lc_number) }
              AND FHLB_ID = #{ quote(member_id) }
            SQL
            credits = []
            begin
              cursor = execute_sql(app.logger, loc_query)
              while row = cursor.fetch_hash()
                credits << row.with_indifferent_access
              end
              Private.format_credits(credits).first
            rescue => e
              app.logger.error(e.message)
              {}
            end
          else
            locs = MAPI::Services::Member::LettersOfCredit.fake_hash('letters_of_credit')
            (locs[:credits].select{ |v| v[:lc_number] == lc_number }.first || locs[:credits].first) if locs.any?
          end
        end

        # private
        module Private
          def self.format_credits(credits)
            credits.collect do |credit|
              {
                lc_number: (credit[:LC_LC_NUMBER].to_s if credit[:LC_LC_NUMBER]),
                sort_code: (credit[:LC_SORT_CODE].to_s if credit[:LC_SORT_CODE]),
                current_par: (credit[:LCX_CURRENT_PAR].to_i if credit[:LCX_CURRENT_PAR]),
                maintenance_charge: (credit[:LCX_TRANS_SPREAD].to_i if credit[:LCX_TRANS_SPREAD]),
                trade_date: (credit[:LC_TRADE_DATE].to_date if credit[:LC_TRADE_DATE]),
                settlement_date: (credit[:LC_SETTLEMENT_DATE].to_date if credit[:LC_SETTLEMENT_DATE]),
                maturity_date: (credit[:LC_MATURITY_DATE].to_date if credit[:LC_MATURITY_DATE]),
                description: (credit[:LC_ISSUE_NUMBER].to_s if credit[:LC_ISSUE_NUMBER]),
                beneficiary: (credit[:LC_BENEFICIARY].to_s if credit[:LC_BENEFICIARY])
              }
            end
          end
        end
      end
    end
  end
end
