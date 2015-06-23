class ResourcesController < ApplicationController

  # GET
  def guides
  end

  # GET
  def download
    case params[:file]
    when 'creditguide'
      filename = 'creditguide.pdf'
    when 'collateralguide'
      filename = 'collateralguide.pdf'
    else
      raise ActiveRecord::RecordNotFound
    end

    send_file Rails.root.join('private', filename), filename: filename
  end

end
