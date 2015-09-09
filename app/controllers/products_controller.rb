class ProductsController < ApplicationController

  before_action do
    @html_class ||= 'white-background'
  end

  # GET
  def index
  end

  # GET
  def arc_embedded
    @last_modified = Date.new(2012,12,1)
  end

  # GET
  def amortizing
    @last_modified = Date.new(2003, 12, 1)
  end

  # GET
  def auction_indexed
    @last_modified = Date.new(2011, 4, 1)
  end

  # GET
  def choice_libor
    @last_modified = Date.new(2015, 4, 1)
  end

  # GET
  def callable
    @last_modified = Date.new(2008, 7, 1)
  end

  # GET
  def frc
    @last_modified = Date.new(2011, 4, 1)
  end

  # GET
  def frc_embedded
    @last_modified = Date.new(2009, 12, 1)
  end

  # GET
  def arc
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def knockout
    @last_modified = Date.new(2012, 12, 1)
  end

  # GET
  def ocn
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def putable
    @last_modified = Date.new(2012, 12, 1)
  end

  # GET
  def vrc
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def sbc
    @last_modified = Date.new(2015, 7, 1)
  end

end
