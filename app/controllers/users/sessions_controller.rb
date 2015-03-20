class Users::SessionsController < Devise::SessionsController
  layout 'external'

  before_filter only: [:select_member, :set_member] do
    @members = MembersService.new(request).all_members
  end

  def select_member
    raise 'No members found!' unless @members.present?
    @members.collect! { |member| [member['name'], member['id']] }
  end

  def set_member
    member_id = params[:member_id].to_i
    valid_ids = @members.collect { |member| member[:id] }
    raise 'invalid member ID!' unless valid_ids.include?(member_id)
    session['member_id'] = member_id
    redirect_to after_sign_in_path_for(current_user)
  end
end
