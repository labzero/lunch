module FlipperHelper
  def feature_enabled?(feature, actor=current_user)
    feature = Rails.application.flipper[feature.to_sym]
    member_id = current_member_id
    member_id ||= actor.member_id if actor
    member = Member.new(member_id) if member_id
    feature.enabled?(actor) || feature.enabled?(member)
  end
end