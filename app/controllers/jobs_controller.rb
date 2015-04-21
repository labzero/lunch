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
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    Tempfile.open('job_result', Rails.root.join('tmp')) do |f|
      begin
        job_status.result.copy_to_local_file(:original, f.path)
        send_data f.read,
                  filename: job_status.result_file_name,
                  type: job_status.result_content_type,
                  disposition: 'attachment'
      ensure
        f.unlink
      end
    end
    job_status.destroy if job_status
  end

  def cancel
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    job_status.canceled! if job_status
    render nothing: true
  end
end
