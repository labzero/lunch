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
  AUTOTRADE_RATES_DATA = 9 # "Calypso" in the WebFlags Admin
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
    if disabled_flags = get_json(:report_disabled, "member/#{member_id}/disabled_reports")
      (disabled_flags & report_flags).length > 0
    end
  end

  def member(member_id)
    get_hash(:member, "member/#{member_id}/")
  end

  def member_contacts(member_id)
    if data = get_hash(:member_contacts, "member/#{member_id}/member_contacts")
      # get CAM phone number from LDAP
      user = nil
      if data[:cam] && data[:cam][:username]
        Devise::LDAP::Connection.admin('intranet').open do |ldap|
          user = fetch_ldap_user_by_account_name(ldap, data[:cam][:username])
        end
      end
      data[:cam][:phone_number] = user['telephoneNumber'].first if user && user['telephoneNumber']
      data
    end
  end

  def quick_advance_enabled_for_member?(member_id)
    if data = get_hash(:quick_advance_enabled_for_member?, "member/#{member_id}/quick_advance_flag")
      data[:quick_advance_enabled]
    end
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
    if data = get_json(:all_members, "member/")
      data.collect! { |member| member.with_indifferent_access }
    end
  end

  def signers_and_users(member_id)
    # hit MAPI to get the full list of signers
    if signers = get_json(:signers_and_users, "member/#{member_id}/signers")
      signers_and_users = []
      Devise::LDAP::Adapter.shared_connection do
        Devise::LDAP::Connection.admin('extranet').open do |ldap|
          users = fetch_ldap_users(ldap, member_id) || []
          usernames = users.blank? ? [] : users.collect(&:username)
          signers.each do |signer|
            roles = signer['roles'].blank? ? [] : signer['roles'].flatten.collect{ |role| User::LDAP_GROUPS_TO_ROLES[role] }.compact
            signers_and_users << {display_name: signer['name'], roles: roles, given_name: signer['first_name'], surname: signer['last_name']} unless usernames.include?(signer['username'])
          end

          users.each do |user|
            signers_and_users << {display_name: user.display_name || user.username, roles: user.roles, surname: user.surname, given_name: user.given_name}
          end
        end
      end
      signers_and_users
    end
  end

  protected

  def fetch_ldap_users(ldap, member_id)
    if group = ldap.search(filter: "(&(CN=FHLB#{member_id.to_i})(objectClass=group))").try(:first)
      group[:member].collect do |dn|
        ldap.search(:base => dn, :scope => Net::LDAP::SearchScope_BaseObject).try(:first)
      end.compact.collect do |entry|
        User.find_or_create_by_ldap_entry(entry)
      end
    end
  end

  def fetch_ldap_user_by_account_name(ldap, username)
    user = ldap.search(filter: "(&(sAMAccountName=#{username})(objectClass=person))").try(:first)
  end

end