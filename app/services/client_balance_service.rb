class ClientBalanceService

  def initialize(member_id)
    @connection = ActiveRecord::Base.establish_connection('cdb').connection if Rails.env == 'production'
    @member_id = member_id
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
  end

  def pledged_collateral
    mortgages_connection_string = <<SQL
    SELECT SUM(NVL(STD_MARKET_VALUE,0))
    FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
    WHERE fhlb_id = #{@member_id}
    GROUP BY fhlb_id
SQL

    securities_connection_string = <<SQL
    SELECT
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AG,0) AS agency_mv,
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AAA,0) AS aaa_mv,
          NVL(V_CONFIRM_SUMMARY_INTRADAY.SBC_MV_AA,0) AS aa_mv
    FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
    WHERE fhlb_id =  #{@member_id}
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
       total_collateral = mortgage_mv + agency_mv + aaa_mv + aa_mv
       {
           mortgages: {absolute: mortgage_mv, percentage: mortgage_mv.fdiv(total_collateral)*100},
           agency: {absolute: agency_mv, percentage: agency_mv.fdiv(total_collateral)*100},
           aaa: {absolute: aaa_mv, percentage: aaa_mv.fdiv(total_collateral)*100},
           aa: {absolute: aa_mv, percentage: aa_mv.fdiv(total_collateral)*100}
       }.with_indifferent_access
     else
       JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'pledged_collateral.json'))).with_indifferent_access
     end
  end

  def total_securities
    pledged_securities_string = <<SQL
      SELECT COUNT(*)
      FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
      WHERE account_type = 'P' AND fhlb_id = #{@member_id}
SQL

    safekept_securities_string = <<SQL
      SELECT COUNT(*)
      FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
      WHERE account_type = 'U' AND fhlb_id = #{@member_id}
SQL
    if @connection
      pledged_securities_cursor = @connection.execute(pledged_securities_string)
      safekept_securities_cursor = @connection.execute(safekept_securities_string)
      pledged_securities, safekept_securities = 0
      while row = pledged_securities_cursor.fetch()
        pledged_securities = row[0]
      end
      while row = safekept_securities_cursor.fetch()
        safekept_securities = row[0]
      end
      total_securities = pledged_securities + safekept_securities
      {
          pledged_securities: {absolute: pledged_securities.to_i, percentage: pledged_securities.fdiv(total_securities)*100},
          safekept_securities: {absolute: safekept_securities.to_i, percentage: safekept_securities.fdiv(total_securities)*100}
      }.with_indifferent_access
    else
      JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'total_securities.json'))).with_indifferent_access
    end
  end

  def effective_borrowing_capacity
    total_capacity_string = <<SQL
      SELECT (REG_BORR_CAP +  SBC_BORR_CAP)
      FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
      WHERE fhlb_id = #{@member_id}
SQL

    unused_capacity_string = <<SQL
      SELECT (EXCESS_REG_BORR_CAP + EXCESS_SBC_BORR_CAP) AS unused_BC
      FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
      WHERE fhlb_id = #{@member_id}
SQL
    if @connection
      total_capacity_cursor = @connection.execute(total_capacity_string)
      unused_capacity_cursor = @connection.execute(unused_capacity_string)
      total_capacity, unused_capacity = 0
      while row = total_capacity_cursor.fetch()
        total_capacity = row[0]
      end
      while row = unused_capacity_cursor.fetch()
        unused_capacity = row[0]
      end
      used_capacity = total_capacity - unused_capacity
      {
          used_capacity: {absolute: used_capacity, percentage: used_capacity.fdiv(total_capacity)*100},
          unused_capacity: {absolute: unused_capacity, percentage: unused_capacity.fdiv(total_capacity)*100}
      }.with_indifferent_access
    else
      JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'effective_borrowing_capacity.json'))).with_indifferent_access
    end
  end

end