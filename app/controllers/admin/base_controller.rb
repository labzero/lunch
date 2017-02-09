class Admin::BaseController < ApplicationController

  layout 'admin'

  skip_before_action :require_member
  before_action :require_admin

  private

  def require_admin
    authorize :web_admin, :show?
  end

end