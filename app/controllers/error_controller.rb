class ErrorController < ApplicationController
  skip_before_action :authenticate_user!

  def standard_error
    raise StandardError
  end

  def maintenance
    render 'maintenance', layout: 'error', :status => 503
  end

end
