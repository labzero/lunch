class WelcomeController < ApplicationController

  def index

  end

  def grid_demo

  end

  def details
    render text: `cat ./REVISION || echo 'No REVISION found!'`
  end
end
