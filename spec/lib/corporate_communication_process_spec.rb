require 'rails_helper'
require 'rake'
require 'corporate_communication/process'

describe CorporateCommunication::Process do
  it { expect(subject).to respond_to(:process_email_html) }
  it { expect(subject).to respond_to(:process_email_attachments) }

  describe '`process_email_html` method', :vcr do
    shared_examples 'process_email_html' do
      let(:email) { Mail.read(email_path) }
      let(:call_method) { subject.process_email_html(email) }
      let(:processed_image) { double('A Processed Image') }

      before do
        allow(subject).to receive(:process_email_image).with(/\Ahttp:\/\/contentz.mkt1700.com\//).and_return(processed_image)
        allow(processed_image).to receive(:[]).with(:fingerprint).and_return(SecureRandom.hex)
      end

      it 'removes images that start with http://open.mkt1700.com/open/log/' do
        expect(call_method[:html]).not_to include('http://open.mkt1700.com/open/log/')
      end
      it 'replaces html element links that start with http://links.mkt1700.com/' do
        expect(call_method[:html]).not_to include('http://links.mkt1700.com/')
      end
    end

    describe 'with a rich email' do
      let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
      include_examples 'process_email_html'

      it 'moves the `style` element from the email\'s `head` node into its `body` node' do
        expect(call_method[:html]).to include('<style type="text/css">')
      end
      it 'prepends the styles contained in the style node with `.corporate-communication-detail-reset`' do
        expect(call_method[:html]).to include('.corporate-communication-detail-reset a')
        expect(call_method[:html]).to include('.corporate-communication-detail-reset p')
      end
      it 'replaces the images with CID references' do
        expect(call_method[:html]).to match(/src=["']?cid:#{processed_image[:fingerprint]}["']?/)
      end
      it 'processes the found images' do
        expect(subject).to receive(:process_email_image).with(/\Ahttp:\/\/contentz.mkt1700.com\//)
        call_method
      end
      it 'returns the processed images' do
        expect(call_method[:images]).to eq([processed_image])
      end
    end

    describe 'with a basic email' do
      let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_no_style.txt') }
      include_examples 'process_email_html'
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

  describe '`process_email_image` method' do
    let(:image_url) { 'http://www.example.com/foo.png' }
    let(:image_response) { double(Net::HTTPOK, body: image_body, content_type: image_content_type) }
    let(:image_body) { SecureRandom.hex }
    let(:image_content_type) { double('A Content Type') }
    let(:attachment) { Mail.read(email_path).attachments.first }
    let(:call_method) { subject.process_email_image(image_url) }
    before do
      allow(Net::HTTP).to receive(:get_response).with(kind_of(URI)).and_return(image_response)
    end
    it 'reencodes the attachment as base64' do
      expect(call_method[:data]).to eq(Base64.encode64(image_response.body))
    end
    it 'generates a SHA-256 digest of the attachment' do
      digest = Digest::SHA2.new << image_response.body
      expect(call_method[:fingerprint]).to eq(digest.to_s)
    end
    it 'includes the original attachment filename' do
      expect(call_method[:name]).to eq('foo.png')
    end
    it 'includes the original attachment content type' do
      expect(call_method[:content_type]).to eq(image_response.content_type)
    end
  end

  describe '`process_email` method' do
    let(:file_path) { double('A Path') }
    let(:expanded_path) { double('An Expanded Path') }
    let(:email_path) { File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt') }
    let(:email) { Mail.read(email_path) }
    let(:email_body) { double('An Email Body') }
    let(:email_attachments) { double('Some Email Attachments') }
    let(:email_images) { double('Some Email Images') }
    let(:call_method) { subject.process_email(email, category) }
    let(:category) { double('A Category') }
    before do
      allow(subject).to receive(:process_email_html).and_return({html: email_body, images: email_images})
      allow(subject).to receive(:process_email_attachments).and_return(email_attachments)
    end
    it 'calls `process_email_html` with the email' do
      expect(subject).to receive(:process_email_html).with(email)
      call_method
    end
    it 'calls `process_email_attachments` with the email' do
      expect(subject).to receive(:process_email_attachments).with(email)
      call_method
    end
    it 'throws an error if it was passed nil' do
      expect{subject.process_email(nil)}.to raise_error
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
    it 'returns a hash with the referenced images' do
      expect(call_method[:images]).to eq(email_images)
    end
  end

  describe '`persist_processed_email` method' do
    let(:email) { JSON.parse(File.read(File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_processed.json'))).first }
    let(:email_id) { email['email_id'] }
    let(:email_date) { email['date'] }
    let(:email_title) { email['title'] }
    let(:email_body) { email['body'] }
    let(:email_category) { email['category'] }
    let(:corporate_communication) { CorporateCommunication.new }
    let(:call_method) { subject.persist_processed_email(email) }

    it 'starts a transaction' do
      expect(CorporateCommunication).to receive(:transaction)
      call_method
    end
    it 'converts the email to an indifferent access hash' do
      expect(email).to receive(:with_indifferent_access).and_call_original
      call_method
    end
    it 'finds or builds a new CorporateCommunication by email_id' do
      expect(CorporateCommunication).to receive(:find_or_initialize_by).with(email_id: email_id).and_call_original
      call_method
    end
    it 'updates the date_sent' do
      expect(call_method.date_sent).to eq(email_date)
    end
    it 'updates the title' do
      expect(call_method.title).to eq(email_title)
    end
    it 'updates the body' do
      expect(call_method.body).to eq(email_body)
    end
    it 'updates the category' do
      expect(call_method.category).to eq(email_category)
    end
    it 'saves the record before persisting the attachments' do
      allow(CorporateCommunication).to receive(:find_or_initialize_by).and_return(corporate_communication)
      expect(corporate_communication).to receive(:save!).ordered
      expect(subject).to receive(:persist_attachments).ordered
      call_method
    end
  end

  describe '`persist_attachments` method' do
    let(:email) { JSON.parse(File.read(File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_processed.json'))).first }
    let(:corporate_communication) { CorporateCommunication.create(email_id: email['email_id'], category: email['category'], date_sent: email['date'], body: email['body'], title: email['title']) }
    let(:call_method) { subject.persist_attachments(corporate_communication, email) }

    it 'converts the email to an indifferent access hash' do
      expect(email).to receive(:with_indifferent_access).and_call_original
      call_method
    end
    it 'starts a transaction' do
      expect(CorporateCommunication).to receive(:transaction).at_least(:once)
      call_method
    end

    [:images, :attachments].each do |collection|
      describe "adding attachment to #{collection}" do
        it 'adds the attachment' do
          call_method
          fingerprints = corporate_communication.send(collection).collect(&:fingerprint)
          email[collection.to_s].each do |attachment|
            expect(fingerprints).to include(attachment['fingerprint'])
          end
        end
        it 'doesnt add an attachment if its fingerprint is already present' do
          call_method
          expect(corporate_communication.send(collection)).to_not receive(:build)
          call_method
        end
        it 'deletes attachments that are missing from the new fingerprint list' do
          fingerprint = SecureRandom.hex
          data = StringIOWithFilename.new(SecureRandom.hex)
          data.content_type = 'text/plain'
          data.original_filename = 'foo'
          record = corporate_communication.send(collection).build(data: data, fingerprint: fingerprint)
          expect(record).to receive(:destroy)
          call_method
        end
      end
    end
    it 'saves the new attachments and images' do
      call_method
      (corporate_communication.attachments + corporate_communication.images).each do |attachment|
        expect(attachment.new_record? || attachment.changed?).to be(false)
      end
    end
  end

  describe '`fetch_and_process_email` method' do
    let(:category_mapping) { {} }
    let(:username) { double('A Username') }
    let(:env_username) { double('A Useranme from ENV') }
    let(:password) { double('A Password') }
    let(:env_password) { double('A Password from ENV') }
    let(:host) { double('A Host') }
    let(:env_host) { double('A Host from ENV') }
    let(:port) { double('A Port', to_i: double(Fixnum)) }
    let(:env_port) { double('A Port from ENV', to_i: double(Fixnum)) }
    let(:connection) { double(Net::IMAP, login: nil, examine: nil, uid_search: [], logout: nil, select: nil, uid_fetch: [], uid_store: nil, close: nil) }
    let(:ca_bundle) { double('CA Bundle Path') }
    let(:call_method) { subject.fetch_and_process_email(category_mapping, username, password, host, port) }

    before do
      allow(Net::IMAP).to receive(:new).and_return(connection)
      allow(ENV).to receive(:[]).with('IMAP_HOST').and_return(env_host)
      allow(ENV).to receive(:[]).with('IMAP_PORT').and_return(env_port)
      allow(ENV).to receive(:[]).with('IMAP_CA_BUNDLE_PATH').and_return(ca_bundle)
      allow(ENV).to receive(:[]).with('IMAP_USERNAME').and_return(env_username)
      allow(ENV).to receive(:[]).with('IMAP_PASSWORD').and_return(env_password)
    end

    describe 'opening the connection' do
      it 'creates a new Net::IMAP connection using the provided host and port' do
        expect(Net::IMAP).to receive(:new).with(host, include(port: port)).and_return(connection)
        call_method
      end

      describe 'default parameters' do
        let(:call_method) { subject.fetch_and_process_email(category_mapping, username, password) }
        it 'defaults the host to the `ENV[IMAP_HOST]` if none is provided' do
          expect(Net::IMAP).to receive(:new).with(env_host, anything).and_return(connection)
          call_method
        end
        it 'defaults the port to the `ENV[IMAP_PORT]` if none is provided' do
          expect(Net::IMAP).to receive(:new).with(anything, include(port: env_port)).and_return(connection)
          call_method
        end
      end

      it 'enables SSL if the port is 993' do
        allow(port).to receive(:to_i).and_return(993)
        expect(Net::IMAP).to receive(:new).with(anything, include(ssl: kind_of(Hash))).and_return(connection)
        call_method
      end
      it 'does not enable SSL if the port is not 993' do
        allow(port.to_i).to receive(:==).with(993).and_return(false)
        expect(Net::IMAP).to receive(:new).with(anything, include(ssl: nil)).and_return(connection)
        call_method
      end

      describe 'if SSL is enabled' do
        before do
          allow(port.to_i).to receive(:==).with(993).and_return(true)
        end
        it 'sets the OpenSSL verification mode to VERIFY_PEER' do
          expect(Net::IMAP).to receive(:new).with(anything, include(ssl: include(verify_mode: OpenSSL::SSL::VERIFY_PEER))).and_return(connection)
          call_method
        end
        it 'sets the OpenSSL CA file to `ENV[IMAP_CA_BUNDLE_PATH`] if present' do
          expect(Net::IMAP).to receive(:new).with(anything, include(ssl: include(ca_file: ca_bundle))).and_return(connection)
          call_method
        end
      end
    end

    describe 'authentication' do
      it 'logs in using the supplied username and password' do
        expect(connection).to receive(:login).with(username, password)
        call_method
      end
      describe 'default parameters' do
        let(:call_method) { subject.fetch_and_process_email(category_mapping) }
        it 'defaults the username to `ENV[IMAP_USERNAME]`' do
          expect(connection).to receive(:login).with(env_username, anything)
          call_method
        end
        it 'defaults the password to `ENV[IMAP_PASSWORD]`' do
          expect(connection).to receive(:login).with(anything, env_password)
          call_method
        end
      end
    end

    it 'examines the `INBOX` (read-only mode)' do
      expect(connection).to receive(:examine).with('INBOX')
      call_method
    end
    it 'searches for `UNSEEN` messages (collecting UIDs in response)' do
      expect(connection).to receive(:uid_search).with('UNSEEN')
      call_method
    end
    it 'logs in, then examines, then searches for messages, then logs out' do
      expect(connection).to receive(:login).ordered
      expect(connection).to receive(:examine).ordered
      expect(connection).to receive(:uid_search).ordered
      expect(connection).to receive(:logout).ordered
      call_method
    end

    describe 'if there are `UNSEEN` messages' do
      let(:message_uids) { double(Array) }
      let(:messages) { [double(Net::IMAP::FetchData), double(Net::IMAP::FetchData), double(Net::IMAP::FetchData)] }
      let(:mail_objects) { [] }
      let(:processed_mail_objects) { [] }
      let(:category) { double('A Category')}
      before do
        allow(connection).to receive(:uid_search).with('UNSEEN').and_return(message_uids)
        allow(connection).to receive(:uid_fetch).with(message_uids, 'RFC822').and_return(messages)
        messages.each do |message|
          attributes = {'UID' => SecureRandom.hex, 'RFC822' => double(String)}
          allow(message).to receive(:attr).and_return(attributes)
          mail_object = double(Mail, subject: double('A Subject'), to: [double('An Email')])
          processed_mail = double('A Processed Email')
          allow(Mail).to receive(:read_from_string).with(attributes['RFC822']).and_return(mail_object)
          allow(subject).to receive(:process_email).with(mail_object, anything).and_return(processed_mail)
          allow(subject).to receive(:persist_processed_email).with(processed_mail).and_return(true)
          category_mapping[mail_object.to.first] = category
          mail_objects << mail_object
          processed_mail_objects << processed_mail
        end
      end
      it 'fetches the `RFC822` version of each message' do
        expect(connection).to receive(:uid_fetch).with(message_uids, 'RFC822').and_return(messages)
        call_method
      end
      it 'converts the `RFC822` messages into Mail objects' do
        messages.each_with_index do |message, i|
          expect(Mail).to receive(:read_from_string).with(message.attr['RFC822']).and_return(mail_objects[i])
        end
        call_method
      end
      it 'looks up the message category based on the To: address' do
        mail_objects.each do |mail_object|
          expect(category_mapping).to receive(:[]).with(mail_object.to.first)
        end
        call_method
      end
      it 'call `process_email` with the Mail object and the category' do
        mail_objects.each do |mail_object|
          expect(subject).to receive(:process_email).with(mail_object, category)
        end
        call_method
      end
      it 'calls `persist_processed_email` with the processed message hash' do
        processed_mail_objects.each do |processed_mail|
          expect(subject).to receive(:persist_processed_email).with(processed_mail)
        end
        call_method
      end
      it 'selects the `INBOX` (read/write mode)' do
        expect(connection).to receive(:select).with('INBOX')
        call_method
      end
      it 'marks all successfully processed emails as `Deleted` and `Seen`' do
        uids = messages.collect { |m| m.attr['UID'] }
        expect(connection).to receive(:uid_store).with(uids, '+FLAGS.SILENT', [:Seen, :Deleted])
        call_method
      end
      it 'does not mark emails that failed to process successfully' do
        index = rand(0..messages.count - 1)
        message = messages[index]
        uids = messages.collect { |m| m.attr['UID'] } - [message.attr['UID']]
        allow(subject).to receive(:persist_processed_email).with(processed_mail_objects[index]).and_return(false)
        expect(connection).to receive(:uid_store).with(uids, anything, anything)
        call_method
      end
      it 'closes the `INBOX` (deletes all `Deleted` messages)' do
        expect(connection).to receive(:close)
        call_method
      end
      it 'searches, fetches, selects, stores, closes and then logs out' do
        expect(connection).to receive(:uid_search).ordered
        expect(connection).to receive(:uid_fetch).ordered
        expect(connection).to receive(:select).ordered
        expect(connection).to receive(:uid_store).ordered
        expect(connection).to receive(:close).ordered
        expect(connection).to receive(:logout).ordered
        call_method
      end
      [:select, :uid_fetch, :uid_store, :close].each do |method|
        it "returns false if an Net::IMAP::Error is raised when `#{method}` is called" do
          allow(connection).to receive(method).and_raise(Net::IMAP::Error)
          expect(call_method).to be(false)
        end
      end
    end

    it 'logs out when done' do
      expect(connection).to receive(:logout)
      call_method
    end
    it 'returns true on success' do
      expect(call_method).to be(true)
    end
    [:login, :examine, :uid_search, :logout].each do |method|
      it "returns false if an Net::IMAP::Error is raised when `#{method}` is called" do
        allow(connection).to receive(method).and_raise(Net::IMAP::Error)
        expect(call_method).to be(false)
      end
    end
  end
end

describe Rake do
  describe 'the corporate_communication:process task' do
    let(:email_path) { double('A Path') }
    let(:category) { double('A Category') }
    let(:processed_email) { double('Processed Email') }
    before do
      load 'lib/tasks/corporate_communication.rake'
      Rake::Task.define_task(:environment)
      allow(CorporateCommunication::Process).to receive(:process_email).and_return(processed_email)
      allow(JSON).to receive(:pretty_generate)
    end
    it 'calls the method `process_email` on the `CorporateCommunication::Process` module with the supplied arguments' do
      expect(CorporateCommunication::Process).to receive(:process_email).with(email_path, category)
      ::Rake::Task["corporate_communication:process"].invoke(email_path, category)
    end
  end
end