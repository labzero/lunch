class ErrorController < ApplicationController
  skip_before_action :authenticate_user!, :check_terms

  def standard_error
    raise StandardError
  end

  def maintenance
    @inline_styles = true
    @skip_javascript = true
    render 'maintenance', layout: 'error', :status => 503
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

end
