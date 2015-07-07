class MembersService < MAPIService
  # Values correspond to the flags returned from the MAPI endpoint for disabled_services
  FINANCING_AVAILABLE_DATA = 1
  CREDIT_OUTSTANDING_DATA = 2
  COLLATERAL_HIGHLIGHTS_DATA  = 3
  FHLB_STOCK_DATA = 4
  STA_BALANCE_AND_RATE_DATA = 5
  COLLATERAL_REPORT_DATA = 6
  STA_DETAIL_DATA = 7
  ADVANCES_DETAIL_DATA = 8
  AUTOTRADE_RATES_DATA = 9
  IRDB_RATES_DATA = 10
  MONTHLY_COFI_DATA = 11
  SEMIANNUAL_COFI_DATA = 12
  TODAYS_CREDIT_ACTIVITY = 13
  CASH_PROJECTIONS_DATA = 14
  MONTHLY_SECURITIES_POSITION = 15
  SECURITIES_TRANSACTION_DATA = 16
  LETTERS_OF_CREDIT_DETAIL_REPORT = 17
  CAPSTOCK_REPORT_BALANCE = 18
  CAPSTOCK_REPORT_ACTIVITY = 19
  CAPSTOCK_REPORT_TRIAL_BALANCE = 20
  CAPSTOCK_REPORT_DIVIDEND_TRANSACTION = 21
  CAPSTOCK_REPORT_DIVIDEND_STATEMENT = 22
  RATE_CURRENT_STANDARD_ARC = 23
  RATE_CURRENT_SBC_ARC = 24
  RATE_CURRENT_STANDARD_FRC = 25
  RATE_CURRENT_SBC_FRC = 26
  RATE_CURRENT_STANDARD_VRC = 27
  RATE_CURRENT_SBC_VRC = 28
  CURRENT_SECURITIES_POSITION = 29
  ADVANCES_DETAIL_HISTORY = 30
  ACCESS_MANAGER = 31
  INVESTMENTS = 32
  SECURITIESBILLSTATEMENT = 33

  def report_disabled?(member_id, report_flags)
    begin
      response = @connection["member/#{member_id}/disabled_reports"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MembersService.disabled_reports encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MembersService.disabled_reports encountered a connection error: #{e.class.name}")
      return nil
    end
    disabled_flags = JSON.parse(response.body)
    (disabled_flags & report_flags).length > 0
  end

  def member(member_id)
    member_id = member_id.to_i
    members = all_members
    members.find {|member| member[:id] == member_id} if members
  end

  def users(member_id)
    users = nil
    Devise::LDAP::Adapter.shared_connection do
      ldap = Devise::LDAP::Connection.admin('extranet')
      ldap.open do |ldap|
        users = fetch_ldap_users(ldap, member_id)
      end
    end
    users
  end

  def all_members
    begin
      response = @connection["member/"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MembersService.all_members encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MembersService.all_members encountered a connection error: #{e.class.name}")
      return nil
    end

    JSON.parse(response.body).collect! { |member| member.with_indifferent_access }
  end

  def signers_and_users(member_id)
    signers_and_users = []
    # hit MAPI to get the full list of signers
    begin
      response = @connection["member/#{member_id}/signers"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MembersService.all_members encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MembersService.all_members encountered a connection error: #{e.class.name}")
      return nil
    end

    signers = JSON.parse(response.body)

    Devise::LDAP::Adapter.shared_connection do
      Devise::LDAP::Connection.admin('extranet').open do |ldap|
        users = fetch_ldap_users(ldap, member_id)
        usernames = users.blank? ? [] : users.collect(&:username)
        signers.each do |signer|
          roles = signer['roles'].blank? ? [] : signer['roles'].flatten.collect{ |role| User::ROLE_MAPPING[role] }.compact
          signers_and_users << {display_name: signer['name'], roles: roles} unless usernames.include?(signer['username'])
        end

        users.each do |user|
          signers_and_users << {display_name: user.display_name || user.username, roles: user.roles}
        end
      end
    end
    signers_and_users
  end

  protected

  def fetch_ldap_users(ldap, member_id)
    users = nil
    group = ldap.search(filter: "(&(CN=FHLB#{member_id.to_i})(objectClass=group))").try(:first)
    if group
      users = group[:member].collect do |dn|
        ldap.search(:base => dn, :scope => Net::LDAP::SearchScope_BaseObject).try(:first)
      end.compact.collect do |entry|
        User.find_or_create_by_ldap_entry(entry)
      end
    end
    users
  end

end