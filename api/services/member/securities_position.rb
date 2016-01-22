module MAPI
  module Services
    module Member
      module SecuritiesPosition
        SECURITIES_FIELD_MAPPINGS = {
          fhlb_id: {current: 'FHLB_ID', monthly: 'FHLB_ID'},
          custody_account_number: {current: 'ADX_BTC_ACCOUNT_NUMBER', monthly: 'ADX_BTC_ACCOUNT_NUMBER'},
          custody_account_type: {current: 'ACCOUNT_TYPE', monthly: 'ACCOUNT_TYPE_LETTER'},
          security_pledge_type: {current: 'SSD_SECURITY_PLEDGE_TYPE', monthly: 'SSD_SECURITY_PLEDGE_TYPE'},
          cusip: {current: 'SSK_CUSIP', monthly: 'SSK_CUSIP'},
          description: {current: 'SSK_DESC1', monthly: 'SSK_DESC1'},
          reg_id: {current: 'SSX_REG_ID', monthly: 'SSX_REG_ID'},
          pool_number: {current: 'SSK_POOL_NUMBER', monthly: 'SSK_POOL_NUMBER'},
          coupon_rate: {current: 'SSX_COUPON_RATE', monthly: 'SSX_COUPON_RATE'},
          maturity_date: {current: 'SSK_MATURITY_DATE', monthly: 'SSK_MATURITY_DATE'},
          original_par: {current: 'SSX_ORIGINAL_PAR', monthly: 'SSD_ORIGINAL_PAR'},
          factor: {current: 'SSX_CURRENT_FACTOR', monthly: 'SSX_CURRENT_FACTOR'},
          factor_date: {current: 'SSX_CUR_FACTOR_DATE', monthly: 'SSX_CUR_FACTOR_DATE'},
          current_par: {current: 'SSX_CURRENT_PAR', monthly: 'SSD_CURRENT_PAR'},
          price: {current: 'SSX_PRICE', monthly: 'SSX_PRICE'},
          price_date: {current: 'SSX_PRICE_DATE', monthly: 'SSX_PRICE_DATE'},
          market_value: {current: 'SSX_MARKET_VALUE', monthly: 'SSD_MARKET_VALUE'}
        }.with_indifferent_access.freeze

        SECURITIES_QUERY_MAPPINGS = {
          as_of_date: {current: 'SSX_BTC_DATE', monthly: 'SSX_BTC_DATE'},
          query_table: {current: 'SAFEKEEPING.SSK_INTRADAY_SEC_POSITION', monthly: 'SAFEKEEPING.SSK_EOM_RPT_VIEW'}
        }.freeze

        STRING_FIELDS = %i(custody_account_number custody_account_type security_pledge_type cusip description pool_number reg_id).freeze
        FLOAT_FIELDS = %i(coupon_rate original_par factor current_par price market_value).freeze
        DATE_FIELDS = %i(maturity_date factor_date price_date).freeze

        def self.securities_position(app, member_id, report_type, options = {custody_account_type:nil})
          original_report_type = report_type.to_sym
          report_type = original_report_type == :managed ? :current : original_report_type
          if app.settings.environment == :production
            selection_string = "#{SECURITIES_QUERY_MAPPINGS[:as_of_date][report_type]}, #{SECURITIES_FIELD_MAPPINGS.collect{|key, value| value[report_type].to_s}.join(',')}"
            securities_query = <<-SQL
              SELECT #{selection_string}
              FROM #{SECURITIES_QUERY_MAPPINGS[:query_table][report_type]}
              WHERE fhlb_id = #{ ActiveRecord::Base.connection.quote(member_id)}
              #{
                if options[:custody_account_type]
                  "AND #{SECURITIES_FIELD_MAPPINGS[:custody_account_type][report_type]} =
                  #{ActiveRecord::Base.connection.quote(options[:custody_account_type])}"
                end
              }
              #{
                if report_type == :monthly
                  "AND SSX_BTC_DATE
                  BETWEEN TO_DATE(#{ActiveRecord::Base.connection.quote(options[:start_date])}, 'YYYY/MM/DD')
                  AND TO_DATE(#{ActiveRecord::Base.connection.quote(options[:end_date])}, 'YYYY/MM/DD')"
                end
              }
            SQL
            securities_cursor = ActiveRecord::Base.connection.execute(securities_query.strip.gsub(/\s+/, " "))
            securities = []
            while row = securities_cursor.fetch_hash()
              securities << row.with_indifferent_access
            end
            as_of_date = securities.first[SECURITIES_QUERY_MAPPINGS[:as_of_date][report_type]]
          else
            as_of_date = options[:end_date] ? options[:end_date].to_date : (Time.zone.today - 1.month).end_of_month
            securities = Private.fake_securities(member_id, as_of_date, report_type, options[:custody_account_type])
          end

          if original_report_type == :managed
            securities = Private.format_securities(securities, :current)

            # Placeholder fields that will eventually be added to Managed Securities.  Unsure yet if they will require
            # an additional lookup, or if the SAFEKEEPING.SSK_INTRADAY_SEC_POSITION view will be updated to include
            # the necessary fields
            securities.each do |security|
              %i(eligibility authorized_by borrowing_capacity).each do |field|
                security[field] = nil
              end
            end
            securities
          else
            return {as_of_date: nil, total_original_par: nil, total_current_par: nil, total_market_value: nil, securities:[]} if securities.blank?

            total_original_par = securities.inject(0) {|sum, security| sum + security[SECURITIES_FIELD_MAPPINGS[:original_par][report_type].to_sym].to_f}
            total_current_par = securities.inject(0) {|sum, security| sum + security[SECURITIES_FIELD_MAPPINGS[:current_par][report_type].to_sym].to_f}
            total_market_value = securities.inject(0) {|sum, security| sum + security[SECURITIES_FIELD_MAPPINGS[:market_value][report_type].to_sym].to_f}

            {
              as_of_date: (as_of_date.to_date if as_of_date),
              total_original_par: total_original_par,
              total_current_par: total_current_par,
              total_market_value: total_market_value,
              securities: Private.format_securities(securities, report_type)
            }
          end
        end

        # private
        module Private
          include MAPI::Shared::Utils
          def self.fake_securities(member_id, as_of_date, report_type, custody_account_type)
            fake_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'current_securities_position.json'))).with_indifferent_access
            rows = []
            r = Random.new(as_of_date.to_time.to_i + as_of_date.day + report_type.to_s.ord)

            r.rand(3..15).times do |i|
              original_par = r.rand(200000..3000000)
              factor = r.rand()
              rows << {
                SECURITIES_FIELD_MAPPINGS[:fhlb_id][report_type] => member_id,
                SECURITIES_FIELD_MAPPINGS[:custody_account_type][report_type] => ['P', 'U'][r.rand(0..1)],
                SECURITIES_QUERY_MAPPINGS[:as_of_date][report_type] => as_of_date,
                SECURITIES_FIELD_MAPPINGS[:custody_account_number][report_type] =>  '082131',
                SECURITIES_FIELD_MAPPINGS[:security_pledge_type][report_type] =>  ['Standard', 'SBC', 'SAFE'][r.rand(0..2)],
                SECURITIES_FIELD_MAPPINGS[:cusip][report_type] =>  fake_data[:cusips][r.rand(0..(fake_data[:cusips].length - 1))],
                SECURITIES_FIELD_MAPPINGS[:description][report_type] =>  fake_data[:descriptions][r.rand(0..(fake_data[:descriptions].length - 1))],
                SECURITIES_FIELD_MAPPINGS[:reg_id][report_type] =>  '88',
                SECURITIES_FIELD_MAPPINGS[:pool_number][report_type] =>  fake_data[:pools][r.rand(0..(fake_data[:pools].length - 1))],
                SECURITIES_FIELD_MAPPINGS[:coupon_rate][report_type] =>  r.rand(0..6) + r.rand.round(3),
                SECURITIES_FIELD_MAPPINGS[:maturity_date][report_type] =>  as_of_date + r.rand(30..2000).days,
                SECURITIES_FIELD_MAPPINGS[:original_par][report_type] =>  original_par,
                SECURITIES_FIELD_MAPPINGS[:factor][report_type] =>  factor,
                SECURITIES_FIELD_MAPPINGS[:factor_date][report_type] =>  as_of_date - r.rand(30..1000).days,
                SECURITIES_FIELD_MAPPINGS[:current_par][report_type] =>  original_par * factor,
                SECURITIES_FIELD_MAPPINGS[:price][report_type] =>  rand(5..115) + r.rand.round(3),
                SECURITIES_FIELD_MAPPINGS[:price_date][report_type] =>  '24-OCT-12',
                SECURITIES_FIELD_MAPPINGS[:market_value][report_type] =>  (original_par * factor) + r.rand(1000..10000)
              }.with_indifferent_access
            end
            custody_account_type ? rows.delete_if{|row| row[SECURITIES_FIELD_MAPPINGS[:custody_account_type][report_type]] != custody_account_type} : rows
          end

          def self.format_securities(securities, report_type)
            securities.collect do |security|
              new_security = {}
              STRING_FIELDS.each do |property|
                new_security[property] = (security[SECURITIES_FIELD_MAPPINGS[property][report_type]].to_s if security[SECURITIES_FIELD_MAPPINGS[property][report_type]])
              end
              FLOAT_FIELDS.each do |property|
                new_security[property] = (security[SECURITIES_FIELD_MAPPINGS[property][report_type]].to_f if security[SECURITIES_FIELD_MAPPINGS[property][report_type]])
              end
              DATE_FIELDS.each do |property|
                new_security[property] = (dateify(security[SECURITIES_FIELD_MAPPINGS[property][report_type]]) if security[SECURITIES_FIELD_MAPPINGS[property][report_type]])
              end
              new_security
            end
          end
        end
      end
    end
  end
end
