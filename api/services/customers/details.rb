module MAPI
  module Services
    module Customers
      module Details
        include MAPI::Shared::Utils
        def self.customer_details(app, logger, email)
          if !email
            return nil
          end
          if app.settings.environment == :production
            customer_sql = <<-SQL
              select
                phone,
                title
              from
                crm.contact con
              where
                con.email = #{ActiveRecord::Base.connection.quote(email)}
            SQL
            customer_data = self.fetch_hash(logger, customer_sql)
          else
            customer_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'customer_details.json')))
          end
          if customer_data
            {
              phone: customer_data['PHONE'],
              title: customer_data['TITLE']
            }
          else
            nil
          end
        end
      end
    end
  end
end