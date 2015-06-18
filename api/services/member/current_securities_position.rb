module MAPI
  module Services
    module Member
      module CurrentSecuritiesPosition
        def self.current_securities_position(app, member_id, custody_account_type=nil)
          if app.settings.environment == :production
            # get current securities custody_account_type from above.  May be blank for this particular member if they had no cash projections as of this date.
            current_securities_query = <<-SQL
              SELECT FHLB_ID, ACCOUNT_TYPE, SSX_BTC_DATE, ADX_BTC_ACCOUNT_NUMBER,
                SSD_SECURITY_PLEDGE_TYPE, SSK_CUSIP, SSK_DESC1,
                SSX_REG_ID, SSK_POOL_NUMBER, SSX_COUPON_RATE, SSK_MATURITY_DATE,
                SSX_ORIGINAL_PAR, SSX_CURRENT_FACTOR, SSX_CUR_FACTOR_DATE, SSX_CURRENT_PAR,
                SSX_PRICE, SSX_PRICE_DATE, SSX_MARKET_VALUE
              FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
              WHERE fhlb_id = #{ ActiveRecord::Base.connection.quote(member_id)}
              #{ 'AND account_type =' + ActiveRecord::Base.connection.quote(custody_account_type) if custody_account_type }
              ORDER BY ACCOUNT_TYPE, SSD_SECURITY_PLEDGE_TYPE, SSK_CUSIP
            SQL
            current_securities_cursor = ActiveRecord::Base.connection.execute(current_securities_query)
            securities = []
            while row = current_securities_cursor.fetch_hash()
              securities << row.with_indifferent_access
            end
            return nil if securities.blank?
            as_of_date = securities.first['SSX_BTC_DATE']
          else
            as_of_date = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
            securities = Private.fake_securities(member_id, as_of_date, custody_account_type)
          end

          total_original_par = securities.inject(0) {|sum, security| sum + security[:SSX_ORIGINAL_PAR].to_f}
          total_current_par = securities.inject(0) {|sum, security| sum + security[:SSX_CURRENT_PAR].to_f}
          total_market_value = securities.inject(0) {|sum, security| sum + security[:SSX_MARKET_VALUE].to_f}

          {
            as_of_date: as_of_date.to_date,
            total_original_par: total_original_par,
            total_current_par: total_current_par,
            total_market_value: total_market_value,
            securities: Private.format_securities(securities)
          }
        end

        # private
        module Private
          def self.fake_securities(member_id, as_of_date, custody_account_type)
            fake_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'current_securities_position.json'))).with_indifferent_access
            rows = []
            r = custody_account_type ? Random.new(as_of_date.to_time.to_i + as_of_date.day + custody_account_type.ord) : Random.new(as_of_date.to_time.to_i + as_of_date.day)

            r.rand(3..15).times do |i|
              original_par = r.rand(200000..3000000)
              factor = r.rand()
              rows << {
                FHLB_ID: member_id,
                ACCOUNT_TYPE: custody_account_type || ['P', 'U'][r.rand(0..1)],
                SSX_BTC_DATE: as_of_date,
                ADX_BTC_ACCOUNT_NUMBER: '082131',
                SSD_SECURITY_PLEDGE_TYPE: ['Standard', 'SBC', 'SAFE'][r.rand(0..2)],
                SSK_CUSIP: fake_data[:cusips][r.rand(0..(fake_data[:cusips].length - 1))],
                SSK_DESC1: fake_data[:descriptions][r.rand(0..(fake_data[:descriptions].length - 1))],
                SSX_REG_ID: '88',
                SSK_POOL_NUMBER: fake_data[:pools][r.rand(0..(fake_data[:pools].length - 1))],
                SSX_COUPON_RATE: r.rand(0..6) + r.rand.round(3),
                SSK_MATURITY_DATE: as_of_date + r.rand(30..2000).days,
                SSX_ORIGINAL_PAR: original_par,
                SSX_CURRENT_FACTOR: factor,
                SSX_CUR_FACTOR_DATE: as_of_date - r.rand(30..1000).days,
                SSX_CURRENT_PAR: original_par * factor,
                SSX_PRICE: rand(5..115) + r.rand.round(3),
                SSX_PRICE_DATE: '24-OCT-12',
                SSX_MARKET_VALUE: (original_par * factor) + r.rand(1000..10000)
              }.with_indifferent_access
            end
            rows
          end

          def self.format_securities(securities)
            securities.collect do |security|
              {
                custody_account_number: security[:ADX_BTC_ACCOUNT_NUMBER].to_s,
                custody_account_type: security[:ACCOUNT_TYPE].to_s,
                security_pledge_type: security[:SSD_SECURITY_PLEDGE_TYPE].to_s,
                cusip: security[:SSK_CUSIP].to_s,
                description: security[:SSK_DESC1].to_s,
                reg_id: security[:SSX_REG_ID].to_s,
                pool_number: security[:SSK_POOL_NUMBER].to_s,
                coupon_rate: security[:SSX_COUPON_RATE].to_f,
                maturity_date: security[:SSK_MATURITY_DATE].to_date,
                original_par: security[:SSX_ORIGINAL_PAR].to_f,
                factor: security[:SSX_CURRENT_FACTOR].to_f,
                factor_date: security[:SSX_CUR_FACTOR_DATE].to_date,
                current_par: security[:SSX_CURRENT_PAR].to_f,
                price: security[:SSX_PRICE].to_f,
                price_date: security[:SSX_PRICE_DATE].to_date,
                market_value: security[:SSX_MARKET_VALUE].to_f
              }
            end
          end
        end
      end
    end
  end
end
