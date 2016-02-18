class AttachmentsController < ApplicationController

  # GET
  def download
    id = params[:id].to_i
    filename = params[:filename].to_s
    attachment = Attachment.find_by(id: id, data_file_name: filename)
    raise ActiveRecord::RecordNotFound unless attachment
    send_data attachment.data_as_string,
      filename: attachment.data.original_filename,
      type: attachment.data.content_type,
      disposition: 'attachment'
  end

end
