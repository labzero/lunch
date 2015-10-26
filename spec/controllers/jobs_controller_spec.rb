require 'rails_helper'

RSpec.describe JobsController, :type => :controller do
  login_user

  describe 'user required actions' do
    it_behaves_like 'a user required action', :get, :status, job_status_id: 5
    it_behaves_like 'a user required action', :get, :download, job_status_id: 34
    it_behaves_like 'a user required action', :get, :cancel, job_status_id: 99
  end

  describe 'controller actions' do
    let(:job_status_id) { rand(1000) }
    let(:current_user) { double('User', id: user_id, :accepted_terms? => true)}
    let(:user_id) { rand(1000) }
    let(:status) { 'some status'}
    let(:job_status) { double('job status instance', status: status) }

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    describe 'GET status' do
      before do
        allow(JobStatus).to receive(:find_by).with({id: job_status_id, user_id: user_id}).and_return(job_status)
      end

      it 'returns a JSON response containing a `job_status`' do
        get :status, job_status_id: job_status_id
        expect(JSON.parse(response.body).with_indifferent_access[:job_status]).to eq(status)
      end
      it 'returns a JSON response containing a `download_url`' do
        get :status, job_status_id: job_status_id
        expect(JSON.parse(response.body).with_indifferent_access[:download_url]).to eq(job_download_path(job_status))
      end
    end

    describe 'GET download' do
      let(:result) { double('a job result attachment') }
      let(:content_type) { double('content type') }
      let(:file_name) { double('file name') }
      let(:path) { double('some/file/path') }
      let(:data) { double('some data') }
      let(:job_status) { double('job status instance', result: result, result_file_name: file_name, result_content_type: content_type, destroy: nil, result_as_string: data) }

      before do
        allow(result).to receive(:copy_to_local_file)
        allow(JobStatus).to receive(:find_by).with({id: job_status_id, user_id: user_id, no_download: false}).and_return(job_status)
      end

      ['pdf', 'xlsx'].each do |format|
        it "sends the job result if the report format is `#{format}`" do
          expect(controller).to receive(:send_data).with(data, {filename: file_name, type: content_type, disposition: 'attachment'}).and_call_original
          get :download, job_status_id: job_status_id, export_format: format
        end
        it 'destroys the job' do
          expect(job_status).to receive(:destroy)
          get :download, job_status_id: job_status_id, export_format: format
        end
      end
    end

    describe 'GET cancel' do
      before do
        allow(JobStatus).to receive(:find_by).with({id: job_status_id, user_id: user_id}).and_return(job_status)
      end

      it 'sets the given job_status to `canceled`' do
        expect(job_status).to receive(:canceled!)
        get :cancel, job_status_id: job_status_id
      end
      it 'renders nothing' do
        allow(job_status).to receive(:canceled!)
        get :cancel, job_status_id: job_status_id
        expect(response.body).to eq('')
      end
    end
  end
end