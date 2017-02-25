module MAPI
  module Mailers
    module InternalMailer

      def self.send_rate_band_alert(type, term, current_rate, starting_rate, rate_band_info, request_id, user_id=nil)
        rate_details = {
          rate: current_rate,
          start_of_day_rate: starting_rate,
          term: term.to_s,
          type: type.to_s,
          rate_band_info: rate_band_info
        }
        MailerJob.perform_later('InternalMailer', 'exceeds_rate_band', rate_details, request_id, user_id)
      end

    end
  end
end