# monkey patch logging from debug to info so that it shows up in our logs

module DeviseLdapAuthenticatable

  class Logger    
    def self.send(message, logger = Rails.logger)
      if ::Devise.ldap_logger
        logger.add 1, "  \e[36mLDAP:\e[0m #{message}"
      end
    end
  end

end