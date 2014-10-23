class WelcomeController < ApplicationController

  def logon

  end

  def layout_demo

  end

  def details
    render text: `cat ./REVISION || echo 'No REVISION found!'`
  end
end
