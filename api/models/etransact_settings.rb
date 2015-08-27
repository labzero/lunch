module MAPI
  module Models
    class EtransactSettings
      include Swagger::Blocks
      swagger_model :EtransactSettings do
        key :required, [
          :auto_approve, :end_of_day_extension, :rate_timeout, :rates_flagged, :rsa_timeout,
          :shareholder_total_daily_limit, :shareholder_web_daily_limit, :maximum_online_term_days, 
          :rate_stale_check
        ]

        property :auto_approve do
          key :type, :boolean
        end
        property :end_of_day_extension do
          key :type, :integer
          key :description, "How long the EOD can be extended when an advance is in progress (in minutes)."
        end
        property :rate_timeout do
          key :type, :integer
          key :description, "How a user can hold on to rate without needing to check if its changed (in seconds)."
        end
        property :rates_flagged do
          key :type, :boolean
        end
        property :rsa_timeout do
          key :type, :integer
        end
        property :shareholder_total_daily_limit do
          key :type, :integer
          key :description, "The total dollar amount that a given member can borrow in a day."
        end
        property :shareholder_web_daily_limit do
          key :type, :integer
          key :description, "The total dollar amount that a given member can borrow on the web in a day."
        end
        property :maximum_online_term_days do
          key :type, :integer
          key :description, "The longest term (in days) that can be gotten on the web."
        end
        property :rate_stale_check do
          key :type, :integer
        end
      end
    end
  end
end