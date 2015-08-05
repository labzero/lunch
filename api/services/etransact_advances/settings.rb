module MAPI
  module Services
    module EtransactAdvances
      module Settings
        SETTINGS_QUERY = <<-SQL
          SELECT * FROM WEB_ADM.AO_SETTINGS
        SQL
        def self.settings(environment)
          settings = {}

          if environment == :production
            settings_cursor = ActiveRecord::Base.connection.execute(SETTINGS_QUERY)
            data = {}
            while settings_cursor && row = settings_cursor.fetch_hash
              data[row['SETTING_NAME']] = row['SETTING_VALUE']
            end
          else
            data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_settings.json')))
          end
          settings['auto_approve'] = data['AutoApprove'] == '1'
          settings['end_of_day_extension'] = data['EndOfDayExtension'].to_i
          settings['rate_timeout'] = data['RateTimeout'].to_i
          settings['rates_flagged'] = data['RatesFlagged'] == 'Y'
          settings['rsa_timeout'] = data['RSATimeout'].to_i
          settings['shareholder_total_daily_limit'] = data['ShareholderTotalDailyLimit'].try(:gsub, ',', '').to_i
          settings['shareholder_web_daily_limit'] = data['ShareholderWebDailyLimit'].try(:gsub, ',', '').to_i
          settings['maximum_online_term_days'] = data['MaximumOnlineTermDays'].to_i
          settings['rate_stale_check'] = data['RateStaleCheck'].to_i
          settings
        end
      end
    end
  end
end