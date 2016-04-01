class MembersController < ApplicationController
  skip_before_action :check_terms
  skip_before_action :authenticate_user!, only: [:logged_out]

  before_filter only: [:select_member, :set_member] do
    redirect_to after_sign_in_path_for(current_user) if current_member_id
    @members = MembersService.new(request).all_members
  end

  before_filter only: [:logged_out] do
    redirect_to after_sign_in_path_for(current_user) if current_user
  end

  def switch_member
    session['member_id'] = nil
    redirect_to members_select_member_path
  end

  def select_member
    raise 'No members found!' unless @members.present?
    @members.collect! { |member| [member['name'], member['id']] }
    render layout: 'external'
  end

  def set_member
    member_id = params[:member_id].to_i
    member = @members.find { |member| member[:id] == member_id }
    raise 'invalid member ID!' unless member
    session['member_id'] = member_id
    session['member_name'] = member[:name]
    store_location_for(:user, reports_profile_path) if params[:visit_profile]
    redirect_to after_sign_in_path_for(current_user)
  end

  def terms
    render layout: 'external'
  end

  # POST
  def accept_terms
    current_user.update_attribute(:terms_accepted_at, DateTime.now)
    current_user.reload
    redirect_to after_sign_in_path_for(current_user)
  end

  # GET
  def logged_out
    render layout: 'external'
  end

  # GET
  def privacy_policy
  end

  # GET
  def terms_of_use
  end

  # GET
  def contact
  end
end
