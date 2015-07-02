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

  describe '`result_as_string` method' do
    let(:call_method) { subject.result_as_string }
    let(:data) { double('Some Data') }
    let(:tempfile) { double('A Tempfile', path: double('A Path'), read: data, unlink: nil) }
    let(:result) { double('Paperclip::Attachment', copy_to_local_file: nil) }
    before do
      allow(subject).to receive(:result).and_return(result)
      allow(Tempfile).to receive(:open).and_yield(tempfile)
    end
    it 'should open a Tempfile' do
      expect(Tempfile).to receive(:open).with('job_result', Rails.root.join('tmp'))
      call_method
    end
    it 'should delete the Tempfile after reading it' do
      expect(tempfile).to receive(:read).ordered
      expect(tempfile).to receive(:unlink).ordered
      call_method
    end
    it 'should delete the Tempfile if an exception occurs' do
      expect(tempfile).to receive(:unlink)
      allow(tempfile).to receive(:read).and_raise('some error')
      expect{call_method}.to raise_error
    end
    it 'should copy the stored file to the Tempfile' do
      expect(result).to receive(:copy_to_local_file).with(:original, tempfile.path)
      call_method
    end
    it 'should return the contents of the Tempfile' do
      expect(call_method).to be(data)
    end
  end

end