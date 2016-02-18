module Stats
  def self.extranet_logins(request=ActionDispatch::TestRequest.new)
    members = MembersService.new(request).all_members
    users = User.extranet_logins
    users_by_member = {}
    users.each do |user|
      key = user.member_id.to_i
      users_by_member[key] ||= []
      users_by_member[key] << user
    end
    results = {}
    users_by_member.each do |member_id, users|
      member = members.find { |m| m[:id] == member_id } || {name: I18n.t('global.unknown')}
      results[member[:name]] = users.collect(&:username).sort
    end
    results
  end
end