module MAPI
  module Services
    module MemberBalance
      include MAPI::Services::Base

      def self.registered(app)
        @connection = ActiveRecord::Base.establish_connection('cdb').connection if app.environment == 'production'

        service_root '/member', app
        swagger_api_root :member do
          # pledged collateral endpoint
          api do
            key :path, '/{id}/balance/pledged_collateral'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve pledged collateral for member'
              key :notes, 'Returns an array of collateral pledged by a member broken down by security type'
              key :type, :MemberBalance
              key :nickname, :memberBalancePledgedCollateral
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
        end

        relative_get "/:id/balance/pledged_collateral" do
          member_id = params[:id]
          mortgages_connection_string = <<-SQL
            SELECT SUM(NVL(STD_MARKET_VALUE,0))
            FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
            WHERE fhlb_id = #{member_id}
            GROUP BY fhlb_id
          SQL

          securities_connection_string = <<-SQL
            SELECT
            NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AG,0) AS agency_mv,
            NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AAA,0) AS aaa_mv,
            NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AA,0) AS aa_mv
            FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
            WHERE fhlb_id =  #{member_id}
          SQL

          if @connection
            mortages_cursor = @connection.execute(mortgages_connection_string)
            securities_cursor = @connection.execute(securities_connection_string)
            mortgage_mv, agency_mv, aaa_mv, aa_mv = 0
            while row = mortages_cursor.fetch()
              mortgage_mv = row[0]
            end
            while row = securities_cursor.fetch()
              agency_mv = row[0]
              aaa_mv = row[1]
              aa_mv = row[2]
            end
            {
              mortgages: mortgage_mv,
              agency: agency_mv,
              aaa: aaa_mv,
              aa: aa_mv
            }.to_json
          else
            File.read(File.join(MAPI.root, 'fakes', 'member_balance_pledged_collateral.json'))
          end
        end
      end
    end
  end
end