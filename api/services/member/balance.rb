module MAPI
  module Services
    module Member
      module Balance
        # pledged collateral
        def self.pledge_collateral(app, member_id)
          member_id = member_id.to_i
          mortgages_connection_string = <<-SQL
          SELECT SUM(NVL(STD_MARKET_VALUE,0))
          FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          GROUP BY fhlb_id
          SQL

          securities_connection_string = <<-SQL
          SELECT
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AG,0) AS agency_mv,
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AAA,0) AS aaa_mv,
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AA,0) AS aa_mv
          FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL

          if app.settings.environment == :production
            mortages_cursor = ActiveRecord::Base.connection.execute(mortgages_connection_string)
            securities_cursor = ActiveRecord::Base.connection.execute(securities_connection_string)
            mortgage_mv = 0
            agency_mv = 0
            aaa_mv = 0
            aa_mv = 0
            while row = mortages_cursor.fetch()
              mortgage_mv = row[0].to_i
              break
            end
            while row = securities_cursor.fetch()
              agency_mv = row[0].to_i
              aaa_mv = row[1].to_i
              aa_mv = row[2].to_i
              break
            end
            {
                mortgages: mortgage_mv,
                agency: agency_mv,
                aaa: aaa_mv,
                aa: aa_mv
            }.to_json
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_balance_pledged_collateral.json'))).to_json
          end
        end

        # total securities
        def self.total_securities(app, member_id)
          member_id = member_id.to_i
          pledged_securities_string = <<-SQL
            SELECT COUNT(*)
            FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
            WHERE account_type = 'P' AND fhlb_id = #{member_id}
          SQL

          safekept_securities_string = <<-SQL
            SELECT COUNT(*)
            FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
            WHERE account_type = 'U' AND fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL

          if app.settings.environment == :production
            pledged_securities_cursor = ActiveRecord::Base.connection.execute(pledged_securities_string)
            safekept_securities_cursor = ActiveRecord::Base.connection.execute(safekept_securities_string)
            pledged_securities = 0
            safekept_securities = 0
            while row = pledged_securities_cursor.fetch()
              pledged_securities = row[0].to_i
              break
            end
            while row = safekept_securities_cursor.fetch()
              safekept_securities = row[0].to_i
              break
            end
            {pledged_securities: pledged_securities, safekept_securities: safekept_securities}.to_json
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_balance_total_securities.json'))).to_json
          end
        end

        # effective_borrowing_capacity
        def self.effective_borrowing_capacity(app, member_id)
          member_id = member_id.to_i
          borrowing_capacity_connection_string = <<-SQL
            SELECT (NVL(REG_BORR_CAP,0) +  NVL(SBC_BORR_CAP,0)) AS total_BC,
            (NVL(EXCESS_REG_BORR_CAP,0) + NVL(EXCESS_SBC_BORR_CAP,0)) AS unused_BC
            FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
            WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL

          if app.settings.environment == :production
            borrowing_capacity_cursor = ActiveRecord::Base.connection.execute(borrowing_capacity_connection_string)
            total_capacity = 0
            unused_capacity = 0
            while row = borrowing_capacity_cursor.fetch()
              total_capacity = row[0].to_i
              unused_capacity = row[1].to_i
              break
            end
            {
                total_capacity: total_capacity,
                unused_capacity: unused_capacity
            }.to_json
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_balance_effective_borrowing_capacity.json'))).to_json
          end
        end
      end
    end
  end
end
