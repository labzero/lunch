module MAPI
  module Services
    module EtransactAdvances
      module Settings
        include MAPI::Shared::Utils

        SETTINGS_QUERY = <<-SQL
          SELECT * FROM WEB_ADM.AO_SETTINGS
        SQL

        SETTING_NAMES_MAPPING = {
          auto_approve: 'AutoApprove',
          end_of_day_extension: 'EndOfDayExtension',
          rate_timeout: 'RateTimeout',
          rates_flagged: 'RatesFlagged',
          rsa_timeout: 'RSATimeout',
          shareholder_total_daily_limit: 'ShareholderTotalDailyLimit',
          shareholder_web_daily_limit: 'ShareholderWebDailyLimit',
          maximum_online_term_days: 'MaximumOnlineTermDays',
          rate_stale_check: 'RateStaleCheck'
        }.with_indifferent_access

        SERVICE_STATUS_SETTING = 'StartUp'

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

        def self.update_settings(app, settings)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              settings.each do |setting_name, setting_value|
                raise MAPI::Shared::Errors::InvalidFieldError.new("#{setting_name} is an invalid setting name", setting_name, setting_value) unless SETTING_NAMES_MAPPING.keys.include?(setting_name.to_s)
                update_settings_sql = <<-SQL
                UPDATE WEB_ADM.AO_SETTINGS
                SET SETTING_VALUE = #{quote(setting_value)}
                WHERE SETTING_NAME = #{quote(SETTING_NAMES_MAPPING[setting_name])}
                SQL
                raise MAPI::Shared::Errors::SQLError, "Failed to update settings with setting name: #{setting_name}" unless execute_sql(app.logger, update_settings_sql)
              end
            end
          end
          true
        end

        def self.enable_service(app)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              enable_service_sql = <<-SQL
              UPDATE WEB_ADM.AO_SETTINGS
              SET SETTING_VALUE = TO_CHAR(sysdate, 'MM/dd/yyyy')
              WHERE SETTING_NAME = #{quote(SERVICE_STATUS_SETTING)}
              SQL
              raise MAPI::Shared::Errors::SQLError, 'Failed to enable etransact service' unless execute_sql(app.logger, enable_service_sql)
            end
          end
          true
        end

        def self.disable_service(app)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              disable_service_sql = <<-SQL
              UPDATE WEB_ADM.AO_SETTINGS
              SET SETTING_VALUE = NULL
              WHERE SETTING_NAME = #{quote(SERVICE_STATUS_SETTING)}
              SQL
              raise MAPI::Shared::Errors::SQLError, 'Failed to disable etransact service' unless execute_sql(app.logger, disable_service_sql)
            end
          end
          true
        end
      end
    end
  end
end