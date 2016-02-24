require 'rails_helper'

RSpec.describe QuickReport, type: :model do
  it { should belong_to(:quick_report_set) }
  it { should have_attached_file(:report) }
  it { should validate_presence_of(:report_name) }
  it { should have_db_index([:quick_report_set_id, :report_name]).unique(true) }
  it { should have_db_index(:report_name).unique(false) }

  it 'includes PaperclipAttachmentAsString' do
    expect(described_class.included_modules).to include(PaperclipAttachmentAsString)
  end

  describe 'scopes' do
    let(:result) { double(ActiveRecord::Relation) }
    describe '`reports_named`' do
      let(:report_names) { double('A Set of Report Names') }
      let(:call_method) { described_class.reports_named(report_names) }
      it_behaves_like 'an ActiveRecord scope', :reports_named
      it 'limits the scope to only records with one of the supplied report names' do
        expect(described_class).to receive(:where).with(report_name: report_names)
        call_method
      end
      it 'returns the result' do
        allow(described_class).to receive(:where).and_return(result)
        expect(call_method).to be(result)
      end
    end
    describe '`completed`' do
      let(:call_method) { described_class.completed }
      it_behaves_like 'an ActiveRecord scope', :completed
      it 'limits the scope to only records that have an attached report' do
        expect(described_class).to receive(:where).with(no_args).and_return(result)
        expect(result).to receive(:not).with(report_file_name: nil)
        call_method
      end
      it 'returns the found record' do
        allow(described_class).to receive_message_chain(:where, :not).and_return(result)
        expect(call_method).to be(result)
      end
    end
  end
end
