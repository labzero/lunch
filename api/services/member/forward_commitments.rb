module MAPI
  module Services
    module Member
      module ForwardCommitments
        def self.forward_commitments(app, member_id)
          if app.settings.environment == :production
            forward_commitments_query = <<-SQL
              SELECT ADVDET_TRADE_DATE, ADVDET_SETTLEMENT_DATE, ADVDET_MATURITY_DATE, ADVDET_ADVANCE_NUMBER, ADVDET_MNEMONIC, ADVDET_CURRENT_PAR, ADVDET_INTEREST_RATE, ADVDET_DATEUPDATE
              FROM web_inet.WEB_ADVANCES_FORWARD_RPT
              WHERE FHLB_ID = #{ ActiveRecord::Base.connection.quote(member_id)}
            SQL

            forward_commitments_cursor = ActiveRecord::Base.connection.execute(forward_commitments_query)
            advances = []
            while row = forward_commitments_cursor.fetch_hash()
              advances << row.with_indifferent_access
            end
            return nil if advances.blank?
            as_of_date = advances.first[:ADVDET_DATEUPDATE]
          else
            as_of_date = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
            advances = Private.fake_advances(member_id, as_of_date)
          end

          total_current_par = advances.inject(0) {|sum, security| sum + security[:ADVDET_CURRENT_PAR].to_i}

          {
            as_of_date: as_of_date.to_date,
            total_current_par: total_current_par,
            advances: Private.format_advances(advances)
          }
        end

        # private
        module Private
          def self.fake_advances(member_id, as_of_date)
            advance_types = ['FRC', 'FRC-REGULAR W/PPS', 'FRC - AMORTIZING']
            rows = []
            r = Random.new(member_id.to_i + as_of_date.to_time.to_i + as_of_date.day)

            settlement_date = as_of_date + r.rand(90..1095).days
            r.rand(1..5).times do |i|
              rows << {
                ADVDET_TRADE_DATE: as_of_date - r.rand(180..730).days,
                ADVDET_SETTLEMENT_DATE: settlement_date,
                ADVDET_MATURITY_DATE: settlement_date + 5.days,
                ADVDET_ADVANCE_NUMBER: r.rand(30000..40000),
                ADVDET_MNEMONIC: advance_types[r.rand(0..(advance_types.length - 1))],
                ADVDET_CURRENT_PAR: r.rand(800000..200000000),
                ADVDET_INTEREST_RATE: [0, (r.rand(0..4) + r.rand.round(2))][r.rand(0..1)]
              }.with_indifferent_access
            end
            rows
          end

          def self.format_advances(advances)
            advances.collect do |advance|
              {
                trade_date: advance[:ADVDET_TRADE_DATE].to_date,
                funding_date: advance[:ADVDET_SETTLEMENT_DATE].to_date,
                maturity_date: advance[:ADVDET_MATURITY_DATE].to_date,
                advance_number: advance[:ADVDET_ADVANCE_NUMBER].to_s,
                advance_type: advance[:ADVDET_MNEMONIC].to_s,
                current_par: advance[:ADVDET_CURRENT_PAR].to_i,
                interest_rate: advance[:ADVDET_INTEREST_RATE].to_f
              }
            end
          end
        end
      end
    end
  end
end
