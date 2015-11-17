require 'rails_helper'

RSpec.describe AttachmentsController, type: :controller do
  login_user

  describe 'GET download' do
    let(:id) { rand(10000..99999) }
    let(:filename) { SecureRandom.hex + '.' + SecureRandom.hex(2) }
    let(:make_request) { get :download, id: id, filename: filename }
    let(:attachment) { FactoryGirl.build(:attachment) }
    let(:data_string) { double('Some Data') }

    before do
      allow(attachment).to receive(:data_as_string).and_return(data_string)
    end

    it_behaves_like 'a user required action', :get, :download, id: rand(10000..99999), filename: SecureRandom.hex
    it 'looks up the Attachment by id and filename' do
      expect(Attachment).to receive(:find_by).with(id: id, data_file_name: filename).and_return(attachment)
      make_request
    end
    it 'rasies an ActiveRecord::RecordNotFound if the attachment can not be found' do
      expect{make_request}.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'sends the attachment via `send_data`' do
      data = attachment.data
      allow(Attachment).to receive(:find_by).and_return(attachment)
      expect(controller).to receive(:send_data).with(data_string, {filename: data.original_filename, type: data.content_type, disposition: 'attachment'}).and_call_original
      make_request
    end
  end

end
