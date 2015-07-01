class JobsController < ApplicationController

  def status
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    data = {job_status: job_status.status,
            download_url: job_download_path(job_status)
    }.to_json
    render json: data
  end

  def download
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id, no_download: false)
    raise ActiveRecord::RecordNotFound unless job_status
    send_data job_status.result_as_string,
      filename: job_status.result_file_name,
      type: job_status.result_content_type,
      disposition: 'attachment'
    job_status.destroy if job_status
  end

  def cancel
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    job_status.canceled! if job_status
    render nothing: true
  end
end
