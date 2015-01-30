class WelcomeController < ApplicationController

  skip_before_action :authenticate_user!

  layout 'external'

  def grid_demo

  end

  def details
    render text: `cat ./REVISION 2>/dev/null || echo 'No REVISION found!'`
  end
end
