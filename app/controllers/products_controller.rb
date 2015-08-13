class ProductsController < ApplicationController

  # GET
  def index
  end

  # GET
  def frc
    @last_modified = Date.new(2011,4,1)
  end

  # GET
  def frc_embedded
    @last_modified = Date.new(2009,12,1)
  end

end