class Admin::AdminController < ApplicationController

  layout 'admin'

  skip_before_action :require_member

end