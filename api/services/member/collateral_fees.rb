module MAPI
  module Services
    module Member
      module CollateralFees
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        COLLATERAL_FEE_MAPPING = {
          release_fee: 'Release',
          custody_fee: 'Custody Fee',
          review_fee: 'Review',
          processing_fee: 'Processing'
        }.freeze

        def self.available_statements(app, member_id)
          unless should_fake?(app)
            report_dates_query = <<-SQL
              SELECT TO_CHAR(ACTIVITY_DATE, 'YYYY-MM-DD')
              FROM FEE_CHARGE@COLAPROD_LINK.WORLD
              WHERE CUSTOMER_MASTER_ID = #{quote(member_id)}
            SQL
            fetch_rows(app.logger, report_dates_query).try(:flatten).try(:uniq)
          else
            available_statements = []
            today = Time.zone.today
            20.times { |i| available_statements << (today - (i + 1).months).end_of_month.iso8601}
            available_statements
          end
        end

        def self.collateral_fees(app, member_id, date)
          collateral_fees = unless should_fake?(app)
            collateral_fees_query = <<-SQL
              SELECT SERVICE_TYPE, CHARGE_AMOUNT, CHARGE_QUANTITY, CHARGE_RATE
              FROM FEE_CHARGE@COLAPROD_LINK.WORLD
              WHERE CUSTOMER_MASTER_ID = #{quote(member_id)}
              AND TRUNC(ACTIVITY_DATE) = TO_DATE(#{quote(date)}, 'YYYY-MM-DD')
            SQL

            fetch_hashes(app.logger, collateral_fees_query, {}, true)
          else
            fake_collateral_fees(member_id, date)
          end
          raise MAPI::Shared::Errors::SQLError, 'Failed to fetch collateral fees' unless collateral_fees

          collateral_fee_statement = {}
          COLLATERAL_FEE_MAPPING.each do |fee_type, service_type|
            fee_info = collateral_fees.select { |collateral_fee| collateral_fee['service_type'] == service_type }.first || {}
            collateral_fee_statement[fee_type] = {
              count: fee_info['charge_quantity'].to_i,
              cost: fee_info['charge_rate'].to_f,
              total: fee_info['charge_amount'].to_f
            }
          end
          collateral_fee_statement
        end

        def self.fake_collateral_fees(member_id, date)
          collateral_fees = []
          r = Random.new(date.to_time.to_i + member_id.to_i)
          COLLATERAL_FEE_MAPPING.values.each do |service_type|
            charge_quantity = r.rand(0..999)
            charge_rate = [0.3, 2.5, 3][r.rand(0..2)]
            collateral_fees << {
              'service_type' => service_type,
              'charge_quantity' => charge_quantity,
              'charge_rate' => charge_rate,
              'charge_amount' => (charge_quantity * charge_rate).round(2)
            }
          end
          collateral_fees
        end
      end
    end
  end
end