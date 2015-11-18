require 'rails_helper'

RSpec.describe JobStatus, :type => :model do
  it { should validate_presence_of(:job_id) }
  it { should have_attached_file(:result) }

  let(:job_id) { 'some-job-id' }
  let(:now) { Time.zone.parse('2014-12-12') }

  it 'should set its `finished_at` attr when its status is changed to `completed`' do
    allow(Time.zone).to receive(:now).and_return(now)
    job_status = JobStatus.create!(job_id: job_id)
    expect(job_status.finished_at).to be_nil
    job_status.completed!
    expect(job_status.finished_at).to eq(now)
  end

  it 'responds to `result_as_string`' do
    expect(subject).to respond_to(:result_as_string)
  end
  
  it 'includes PaperclipAttachmentAsString' do
    expect(described_class.included_modules).to include(PaperclipAttachmentAsString)
  end

end