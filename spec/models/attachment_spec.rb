require 'rails_helper'

RSpec.describe Attachment, type: :model do
  it { should belong_to(:owner) }
  it { should have_attached_file(:data) }
  it { should validate_presence_of(:owner_id) }
  it { should validate_presence_of(:owner_type) }

  it 'includes PaperclipAttachmentAsString' do
    expect(described_class.included_modules).to include(PaperclipAttachmentAsString)
  end

  it 'responds to `data_as_string`' do
    expect(subject).to respond_to(:data_as_string)
  end
  
end
