class ErrorController < ApplicationController
  skip_before_action :authenticate_user!

  def standard_error
    raise StandardError
  end

end
