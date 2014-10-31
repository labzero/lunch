class WelcomeController < ApplicationController

  layout 'external'

  def index

  end

  def grid_demo

  end

  def details
    render text: `cat ./REVISION 2>/dev/null || echo 'No REVISION found!'`
  end
end
