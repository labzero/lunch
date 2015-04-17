class JobsController < ApplicationController
  before_action do
    @user_id = current_user.id
  end

  def status
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    data = {job_status: job_status.status,
            export_format: params[:export_format],
            download_url: job_download_path(job_status)
    }.to_json
    render json: data
  end

  def download
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    case params[:export_format]
      when 'pdf', 'xlsx'
        send_file job_status.result.path,
                  filename: job_status.result_file_name,
                  type: job_status.result_content_type,
                  disposition: 'attachment'
      else
        render nothing: true, status: 500 #TODO write a proper failure state -
    end
    job_status.delete if job_status
  end

  def cancel
    id = params[:job_status_id].to_i
    job_status = JobStatus.find_by(id: id, user_id: current_user.id)
    job_status.update_attributes!(status: 'canceled') if job_status
    render nothing: true
  end
end
