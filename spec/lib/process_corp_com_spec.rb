require 'rails_helper'
require 'rake'
require 'process_corp_com'

describe ProcessCorpCom do
  it { expect(subject).to respond_to(:process_email_html) }
  it { expect(subject).to respond_to(:process_email_attachments) }

  describe '`process_email_html` method', :vcr do
    let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
    let(:email) { Mail.read(email_path) }

    it 'moves the `style` element from the email\'s `head` node into its `body` node' do
      expect(subject.process_email_html(email)).to include('<style type="text/css">')
    end
    it 'prepends the styles contained in the style node with `.corporate-communication-detail-reset`' do
      expect(subject.process_email_html(email)).to include('.corporate-communication-detail-reset a')
      expect(subject.process_email_html(email)).to include('.corporate-communication-detail-reset p')
    end
    it 'removes images that start with http://open.mkt1700.com/open/log/' do
      expect(subject.process_email_html(email)).not_to include('http://open.mkt1700.com/open/log/')
    end
    it 'replaces html element links that start with http://links.mkt1700.com/' do
      expect(subject.process_email_html(email)).not_to include('http://links.mkt1700.com/')
    end
  end

  describe '`process_email_attachment` method' do
    let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
    let(:attachment) { Mail.read(email_path).attachments.first }
    let(:call_method) { subject.process_email_attachment(attachment) }
    it 'reencodes the attachment as base64' do
      expect(call_method[:data]).to eq(Base64.encode64(attachment.body.decoded))
    end
    it 'generates a SHA-256 digest of the attachment' do
      digest = Digest::SHA2.new << attachment.body.decoded
      expect(call_method[:fingerprint]).to eq(digest.to_s)
    end
    it 'includes the original attachment filename' do
      expect(call_method[:name]).to eq(attachment.filename)
    end
    it 'includes the original attachment content type' do
      expect(call_method[:content_type]).to eq(attachment.mime_type)
    end
  end

  describe '`process_email_attachments` method' do
    let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
    let(:email) { Mail.read(email_path) }
    let(:call_method) { subject.process_email_attachments(email) }
    let(:attachment) { double('An Attachment') }
    before do
      allow(subject).to receive(:process_email_attachment).with(kind_of(Mail::Part)).and_return(attachment)
    end
    it 'calls `process_email_attachment` on each attachment' do
      expect(call_method).to eq([attachment])
    end
  end

  describe '`process_email` method' do
    let(:file_path) { double('A Path') }
    let(:expanded_path) { double('An Expanded Path') }
    let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
    let(:email) { Mail.read(email_path) }
    let(:email_body) { double('An Email Body') }
    let(:email_attachments) { double('Some Email Attachments') }
    let(:call_method) { subject.process_email(file_path, category) }
    let(:category) { double('A Category') }
    before do
      allow(File).to receive(:expand_path).and_return(expanded_path)
      allow(Mail).to receive(:read).with(expanded_path).and_return(email)
      allow(subject).to receive(:process_email_html).and_return(email_body)
      allow(subject).to receive(:process_email_attachments).and_return(email_attachments)
    end
    it 'expands the path' do
      expect(File).to receive(:expand_path).with(file_path)
      call_method
    end
    it 'calls `process_email_html` with the email' do
      expect(subject).to receive(:process_email_html).with(email)
      call_method
    end
    it 'calls `process_email_attachments` with the email' do
      expect(subject).to receive(:process_email_attachments).with(email)
      call_method
    end
    it 'throws an error if it cannot find the file it was passed' do
      allow(File).to receive(:expand_path).and_call_original
      allow(Mail).to receive(:read).and_call_original
      expect{subject.process_email('some_nonexistant_file.txt')}.to raise_error(Errno::ENOENT)
    end
    it 'returns a hash with the result of `process_email_html`' do
      expect(call_method[:body]).to be(email_body)
    end
    it 'returns a hash with the result of `process_email_attachments`' do
      expect(call_method[:attachments]).to be(email_attachments)
    end
    it 'returns a hash with the email subject' do
      expect(call_method[:title]).to eq(email.subject)
    end
    it 'returns a hash with the email message ID' do
      expect(call_method[:email_id]).to eq(email.message_id)
    end
    it 'returns a hash with the email date' do
      expect(call_method[:date]).to eq(email.date)
    end
    it 'returns a hash with the supplied category' do
      expect(call_method[:category]).to eq(category)
    end
  end
end

describe Rake do
  describe 'the process:corp_com task' do
    let(:email_path) { double('A Path') }
    let(:category) { double('A Category') }
    let(:processed_email) { double('Processed Email') }
    before do
      load 'lib/tasks/process_corp_com.rake'
      Rake::Task.define_task(:environment)
      allow(ProcessCorpCom).to receive(:process_email).and_return(processed_email)
      allow(JSON).to receive(:pretty_generate)
    end
    it 'calls the method `process_email` on the `ProcessCorpCom` module with the supplied arguments' do
      expect(ProcessCorpCom).to receive(:process_email).with(email_path, category)
      ::Rake::Task["process:corp_com"].invoke(email_path, category)
    end
  end
end