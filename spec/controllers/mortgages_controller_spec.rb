require 'rails_helper'
include CustomFormattingHelper
include ContactInformationHelper

RSpec.describe MortgagesController, :type => :controller do
  login_user

  let(:member_id) { rand(9999..99999) }

  before { allow(controller).to receive(:current_member_id).and_return(member_id) }

  shared_examples 'a MortgagesController action that sets page-specific instance variables with a before filter' do
    it 'sets the active nav to `:mortgages`' do
      expect(controller).to receive(:set_active_nav).with(:mortgages)
      call_action
    end
    it 'sets the `@html_class` to `white-background` if no class has been set' do
      call_action
      expect(assigns[:html_class]).to eq('white-background')
    end
    it 'does not set `@html_class` if it has already been set' do
      html_class = instance_double(String)
      controller.instance_variable_set(:@html_class, html_class)
      call_action
      expect(assigns[:html_class]).to eq(html_class)
    end
  end

  RSpec.shared_examples 'it checks the `request?` `mortgage` policy' do
    before { allow(subject).to receive(:authorize).and_call_original }
    it 'checks if the current user is allowed to edit trade rules' do
      expect(subject).to receive(:authorize).with(:mortgage, :request?)
      call_action
    end
    it 'raises any errors raised by checking to see if the user is authorized to modify the advance' do
      error = Pundit::NotAuthorizedError
      allow(subject).to receive(:authorize).and_raise(error)
      expect{call_action}.to raise_error(error)
    end
  end

  describe 'get `new`' do
    allow_policy :mortgage, :request?

    let(:today) { Time.zone.today }
    let(:call_action) { get :new }
    let(:member_info) { double('member info') }
    let(:member_balance_service) { double('member balance service') }
    let(:due_string) { SecureRandom.hex }
    let(:due_datetime) { double('due datetime') }
    let(:extension_string) { SecureRandom.hex }
    let(:extension_datetime) { double('extension datetime') }
    let(:file_types) { JSON.parse('[ { "id" : 5,
                           "value" : "COMPLETE",
                           "nameSpecific" : "Complete",
                           "nameBlanketLien" : "Standard",
                           "pledgeTypes" : [ "FHLB" ]
                         }, {
                           "id" : 3,
                           "value" : "DEPLEDGE",
                           "nameSpecific" : "Depledge",
                           "nameBlanketLien" : "Delete",
                           "pledgeTypes" : [ "FHLB" ]
                         }, {
                           "id" : 1,
                           "value" : "PLEDGE",
                           "nameSpecific" : "Pledge",
                           "nameBlanketLien" : "Add",
                           "pledgeTypes" : [ "FHLB" ]
                         }, {
                           "id" : 4,
                           "value" : "RENUMBER",
                           "nameSpecific" : "Renumber",
                           "nameBlanketLien" : "Renumber",
                           "pledgeTypes" : [ "FHLB" ]
                         } ]') }
    before do
      allow(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
      allow(member_balance_service).to receive(:mcu_member_info).and_return(member_info)
      allow(Time.zone).to receive(:parse)
      allow(member_info).to receive(:[])
      allow(member_info).to receive(:[]).with('mcuDueDate').and_return(due_string)
      allow(member_info).to receive(:[]).with('mcuExtendedDate').and_return(extension_string)
      allow(member_info).to receive(:[]).with('blanketLien').and_return(true)
      allow(member_info).to receive(:[]).with('mcuuFileTypes').and_return(file_types)
    end

    it_behaves_like 'a MortgagesController action that sets page-specific instance variables with a before filter'
    it_behaves_like 'it checks the `request?` `mortgage` policy'
    it 'sets the `@title`' do
      call_action
      expect(assigns[:title]).to eq(I18n.t('mortgages.new.title'))
    end
    it 'parses the due date' do
      expect(Time.zone).to receive(:parse).with(due_string)
      call_action
    end
    it 'sets the `@due_datetime`' do
      allow(Time.zone).to receive(:parse).with(due_string).and_return(due_datetime)
      call_action
      expect(assigns[:due_datetime]).to eq(due_datetime)
    end
    it 'parses the extension date' do
      expect(Time.zone).to receive(:parse).with(extension_string)
      call_action
    end
    it 'sets the `@extension_datetime`' do
      allow(Time.zone).to receive(:parse).with(extension_string).and_return(extension_datetime)
      call_action
      expect(assigns[:extension_datetime]).to eq(extension_datetime)
    end
    it 'does not add blanket lien option to `@pledge_type_dropdown_options` if `member_info["blanketLien"]` is false' do
      allow(member_info).to receive(:[]).with('blanketLien').and_return(false)
      call_action
      expect(assigns[:pledge_type_dropdown_options]).to eq(described_class::PLEDGE_TYPE_DROPDOWN)
    end
    it 'assigns `@mcu_type_dropdown_options`' do
      call_action
      expect(assigns[:mcu_type_dropdown_options]).to eq(file_types.map { |type| type['nameSpecific'] }.zip(file_types.map { |type| "#{type['id']}_#{type['value']}" }))
    end
    it 'assigns `@program_type_dropdowns`' do
      call_action
      expect(assigns[:program_type_dropdowns]).to eq(Hash[file_types.map { |type| "#{type['id']}_#{type['value']}" }.zip(file_types.map { |type| [[type['pledgeTypes'][0], type['pledgeTypes'][0]]] })])
    end
    it 'assigns `@accepted_upload_mimetypes' do
      call_action
      expect(assigns[:accepted_upload_mimetypes]).to eq(described_class::ACCEPTED_UPLOAD_MIMETYPES.join(', '))
    end
    it 'sets `@session_elevated` to the result of `session_elevated?`' do
      session_elevated = double('session info')
      allow(controller).to receive(:session_elevated?).and_return(session_elevated)
      call_action
      expect(assigns[:session_elevated]).to eq(session_elevated)
    end
    describe 'when `member_info` is `nil`' do
      let(:error_message) { 'No MCU member info returned from the MCM message bus' }
      before do
        allow(member_info).to receive(:present?).and_return(false)
      end
      it 'catches the error and assigns it to `@error`' do
        call_action
        expect(assigns[:error]).to eq(error_message)
      end
      it 'logs the error message' do
        expect(subject.logger).to receive(:error).with(error_message)
        call_action
      end
    end
  end

  describe 'get `manage`' do
    let(:today) { Time.zone.today }
    let(:call_action) { get :manage }
    let(:member_info) { double('member info') }
    let(:due_datetime) { Time.zone.today + rand(1..30).days }
    let(:extension_datetime) { Time.zone.today + rand(1..30).days }
    let(:member_balance_service) { instance_double(MemberBalanceService, mcu_member_status: [], mcu_member_info: []) }
    before {
      allow(Time.zone).to receive(:today).and_return(today)
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
      allow(member_balance_service).to receive(:mcu_member_info).and_return(member_info)
      allow(member_info).to receive(:[]).with(:mcuDueDate).and_return(due_datetime)
      allow(member_info).to receive(:[]).with(:mcuExtendedDate).and_return(extension_datetime)
    }

    it_behaves_like 'a MortgagesController action that sets page-specific instance variables with a before filter'
    it 'sets the `@title`' do
      call_action
      expect(assigns[:title]).to eq(I18n.t('mortgages.manage.title'))
    end
    describe 'when `mcu_member_info` is `nil`' do
      let(:error_message) { 'No MCU member info returned from the MCM message bus' }
      before do
        allow(member_balance_service).to receive(:mcu_member_info).and_return(nil)
      end
      it 'assigns `@error`' do
        call_action
        expect(assigns[:error]).to eq(error_message)
      end
      it 'logs the error message' do
        expect(subject.logger).to receive(:error).with(error_message)
        call_action
      end
    end
    it 'sets `@due_datetime` to a day one week from today, at 5pm' do
      call_action
      expect(assigns[:due_datetime]).to eq(due_datetime)
    end
    it 'sets `@extension_datetime` to a day two weeks from today, at 5pm' do
      call_action
      expect(assigns[:extension_datetime]).to eq(extension_datetime)
    end
    describe '`@table_data`' do
      it 'has the proper `column_headings`' do
        column_headings = [I18n.t('mortgages.manage.transaction_number'),
                           I18n.t('mortgages.manage.upload_type'),
                           I18n.t('mortgages.manage.authorized_by'),
                           I18n.t('mortgages.manage.authorized_on'),
                           I18n.t('mortgages.manage.status'),
                           I18n.t('mortgages.manage.number_of_loans'),
                           I18n.t('mortgages.manage.number_of_errors'),
                           I18n.t('mortgages.manage.action')]
        call_action
        expect(assigns[:table_data][:column_headings]).to eq(column_headings)
      end
      describe 'table `rows`' do
        it 'is an empty array if there are no mcus' do
          allow(member_balance_service).to receive(:mcu_member_status).and_return([])
          call_action
          expect(assigns[:table_data][:rows]).to eq([])
        end
        it 'builds a row for each letter of credit returned by `dedupe_locs`' do
          n = rand(1..10)
          mcu = []
          n.times { mcu << {transaction_id: SecureRandom.hex} }
          allow(member_balance_service).to receive(:mcu_member_status).and_return(mcu)
          call_action
          expect(assigns[:table_data][:rows].length).to eq(n)
        end
        describe 'populated rows' do
          let(:mcu) { {transaction_id: double('transactionId'), mcu_type: double('mcu_type'), authorizedBy: double('authorizedBy'), authorizedOn: double('authorizedOn'), status: double('status'), numberOfLoans: double('numberOfLoans'), numberOfErrors: double('numberOfErrors') } }
          before { allow(member_balance_service).to receive(:mcu_member_status).and_return([mcu]) }

          it 'calls `translated_mcu_transaction` with each mcu transaction' do
            expect(controller).to receive(:translated_mcu_transaction).and_return({})
            call_action
          end
          value_types = [[:transactionId, nil], [:mcuType, nil], [:authorizedBy, nil], [:authorizedOn, :date], [:status, nil], [:numberOfLoans, nil], [:numberOfErrors, nil]]
          value_types.each_with_index do |attr, i|
            attr_name = attr.first
            attr_type = attr.last
            describe "columns with cells based on the MCU attribute `#{attr_name}`" do
              before { allow(controller).to receive(:translated_mcu_transaction).and_return(mcu) }

              it "builds a cell with a `value` of `#{attr_name}`" do
                call_action
                expect(assigns[:table_data][:rows].length).to be > 0
                assigns[:table_data][:rows].each do |row|
                  expect(row[:columns][i][:value]).to eq(mcu[attr_name])
                end
              end
              it "builds a cell with a `type` of `#{attr_type}`" do
                call_action
                expect(assigns[:table_data][:rows].length).to be > 0
                assigns[:table_data][:rows].each do |row|
                  expect(row[:columns][i][:type]).to eq(attr_type)
                end
              end
            end
          end
          describe 'the `view_details` column' do
            let(:view_details_column) { call_action; assigns[:table_data][:rows][0][:columns].last }
            before { allow(controller).to receive(:translated_mcu_transaction).and_return(mcu) }

            it 'builds a cell with a `type` of `:link_list`' do
              expect(view_details_column[:type]).to eq(:link_list)
            end
            describe 'the `value` of the cell' do
              it "is an array in an array whose first member is `#{I18n.t('mortgages.manage.actions.view_details')}`" do
                expect(view_details_column[:value].first.first).to eq(I18n.t('mortgages.manage.actions.view_details'))
              end
              it 'is an array in an array whose second member is the `mcu_view_transaction_path` with the `transactionId` of the mcu transaction' do
                expect(view_details_column[:value].first.last).to eq(mcu_view_transaction_path(transaction_id: mcu[:transactionId]))
              end
            end
          end
        end
      end
    end
  end

  describe 'get `view`' do
    let(:transaction_id) { SecureRandom.hex }
    let(:matching_transaction) { {transactionId: transaction_id} }
    let(:unmatching_transaction) { {transactionId: SecureRandom.hex} }
    let(:member_balance_service) { instance_double(MemberBalanceService, mcu_member_status: [unmatching_transaction, matching_transaction]) }
    let(:call_action) { get :view, transactionId: transaction_id }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
      allow(subject.logger).to receive(:error).with(anything)
    end
    it_behaves_like 'a MortgagesController action that sets page-specific instance variables with a before filter'
    it 'sets the `@title` appropriately' do
      call_action
      expect(assigns[:title]).to eq(I18n.t('mortgages.view.title'))
    end
    it 'creates a new instance of `MemberBalanceService` with the member_id and request' do
      expect(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
      call_action
    end
    it 'calls `mcu_member_status` on the instance of `MemberBalanceService`' do
      expect(member_balance_service).to receive(:mcu_member_status).and_return([unmatching_transaction, matching_transaction])
      call_action
    end
    describe 'when `mcu_member_status` returns nil' do
      let(:error_message) { 'There has been an error and MortgagesController#view has encountered nil. Check error logs.' }
      before do
        allow(member_balance_service).to receive(:mcu_member_status).and_return(nil)
      end      
      it 'assigns `@error` to an error message' do
        call_action
        expect(assigns[:error]).to eq(error_message)
      end
      it 'logs the error message' do
        expect(subject.logger).to receive(:error).with(error_message)
        call_action
      end
    end
    describe 'when no matching transactions are returned from `mcu_member_status`' do
      let(:error_message) { "No matching MCU Status found for MCU with transactionId: #{transaction_id}" }
      before do
        allow(member_balance_service).to receive(:mcu_member_status).and_return([unmatching_transaction])
      end
      it 'assigns `@error` to an error message' do
        call_action
        expect(assigns[:error]).to eq(error_message)
      end
      it 'logs the error message' do
        expect(subject.logger).to receive(:error).with(error_message)
        call_action
      end
    end
    describe 'when a matching transaction is included in the set returned by `mcu_member_status`' do
      let(:translated_transaction_details) { instance_double(Hash) }
      it 'calls `translated_mcu_transaction` with the mcu transaction that has the same `transaction_id` as the passed `transactionId` param' do
        expect(controller).to receive(:translated_mcu_transaction).with(matching_transaction)
        call_action
      end
      it 'does not call `translated_mcu_transaction` with any mcu transactions that have different `transaction_id` than the passed `transactionId` param' do
        expect(controller).not_to receive(:translated_mcu_transaction).with(unmatching_transaction)
        call_action
      end
      it 'sets `@transaction_details` to the result of calling `translated_mcu_transaction`' do
        allow(controller).to receive(:translated_mcu_transaction).and_return(translated_transaction_details)
        call_action
        expect(assigns[:transaction_details]).to eq(translated_transaction_details)
      end
    end
  end

  describe 'post `upload`' do
    let(:transaction_id) { SecureRandom.hex }
    let(:transaction_id_response) { { transaction_id: transaction_id } }
    let(:path) { SecureRandom.hex }
    let(:original_filename) { 'upload-test-file.txt' }
    let(:file) { fixture_file_upload(original_filename, 'text/text') }
    let(:mcu_type) { "#{rand(1..5)}_#{SecureRandom.hex}" }
    let(:pledge_type) { SecureRandom.hex }
    let(:program_type) { SecureRandom.hex }
    let(:username) { SecureRandom.hex }
    let(:member_balance_service) { instance_double( MemberBalanceService, 
                                                    mcu_transaction_id: transaction_id,
                                                    mcu_upload_file: nil )}
    let(:username) { SecureRandom.hex }
    let(:user) { instance_double(User, username: username, accepted_terms?: true) }
    let(:collateral_operations_email) { SecureRandom.hex }
    let(:collateral_operations_phone) { SecureRandom.hex }
    let(:result) { { success: true, message: '' } }
    let(:year) { SecureRandom.hex }      
    let(:month) { SecureRandom.hex }
    let(:now) { instance_double(Time, year: year, month: month) }
    let(:server_info) { instance_double(Hash, :[] => nil) }
    let(:archive_dir) { SecureRandom.hex }
    let(:hostname) { SecureRandom.hex }
    let(:svc_account_username) { SecureRandom.hex }
    let(:svc_account_password) { SecureRandom.hex }
    let(:local_path) { SecureRandom.hex }
    let(:remote_filename) { "#{pledge_type}_#{transaction_id}_#{original_filename.gsub(' ', '_')}" }
    let(:remote_path_fragment) { "#{archive_dir}/MCU/#{member_id}" }
    let(:remote_path_fragment_with_year) { "#{remote_path_fragment}/#{year}" }
    let(:remote_path_fragment_with_year_and_month) { "#{remote_path_fragment_with_year}/#{month}" }
    let(:remote_path) { "#{remote_path_fragment_with_year_and_month}/#{remote_filename}" }
    let(:sftp) { double('sftp') }
    let(:call_action) { get :upload, 
                        mortgage_collateral_update: { file: file,
                                                      mcu_type: mcu_type,
                                                      pledge_type: pledge_type,
                                                      "program_type_#{mcu_type}": program_type } }
    before do 
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
      allow(member_balance_service).to receive(:mcu_transaction_id).and_return(transaction_id_response)
      allow(transaction_id_response).to receive(:[]).and_return(transaction_id)
      allow(member_balance_service).to receive(:mcu_upload_file)
      allow(file).to receive(:path).and_return(path)
      allow(file).to receive(:original_filename).and_return(original_filename)
      allow(subject).to receive(:current_user).and_return(user)
      allow(pledge_type).to receive(:titlecase).and_return(pledge_type)
      allow(program_type).to receive(:titlecase).and_return(program_type)
      allow(controller).to receive(:collateral_operations_email).and_return(collateral_operations_email)      
      allow(member_balance_service).to receive(:mcu_upload_file).and_return(result)
      allow(member_balance_service).to receive(:mcu_server_info).and_return(server_info)
      allow(Time.zone).to receive(:now).and_return(now)
      allow(server_info).to receive(:[]).with('archiveDir').and_return(archive_dir)
      allow(server_info).to receive(:[]).with('hostname').and_return(hostname)
      allow(server_info).to receive(:[]).with('svcAccountUsername').and_return(svc_account_username)
      allow(server_info).to receive(:[]).with('svcAccountPassword').and_return(svc_account_password)
      allow(original_filename).to receive(:gsub).and_return(original_filename)
      allow(Net::SFTP).to receive(:start).and_yield(sftp)
      allow(sftp).to receive(:mkdir).with(anything)
      allow(file).to receive(:path).and_return(local_path)
      allow(sftp).to receive(:upload!)
    end
    it 'create a `MemberBalanceService` instance' do
      expect(MemberBalanceService).to receive(:new).with(member_id, request)
      call_action
    end
    it 'gets the `transaction_id_response` from the member balance service instance' do
      expect(member_balance_service).to receive(:mcu_transaction_id).and_return(transaction_id_response)
      call_action
    end
    describe 'when the `transaction_id_response` is missing' do
      before do 
        allow(transaction_id_response).to receive(:present?).and_return(false)
      end
      it 'logs an error' do
        expect(subject.logger).to receive(:error).with('No transaction id response returned from the MCM message bus')
        call_action
      end
      it 'sets the error result' do
        allow(controller).to receive(:collateral_operations_email).and_return(collateral_operations_email)
        allow(controller).to receive(:collateral_operations_phone_number).and_return(collateral_operations_phone_number)
        call_action
        expect(assigns[:result]).to eq({ success: false, message: I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe})
      end
    end
    describe 'when the `transaction_id_response` is present' do
      before do 
        allow(transaction_id_response).to receive(:present?).and_return(true)
      end
      it 'gets the `transaction_id` from the json response' do
        expect(transaction_id_response).to receive(:[]).with(:transaction_id).and_return(transaction_id)
        call_action
      end
      it 'assigns the `transaction_id` to `@transaction_id`' do
        allow(transaction_id_response).to receive(:[]).with(:transaction_id).and_return(transaction_id)
        call_action
        expect(assigns[:transaction_id]).to eq(transaction_id)
      end        
      describe 'when the `transaction_id` is `nil`' do
        before do
          allow(transaction_id_response).to receive(:[]).with(:transaction_id).and_return(nil)
        end
        it 'logs the error message' do
          expect(subject.logger).to receive(:error).with('No transaction id returned from the MCM message bus')
          call_action
        end
        it 'sets the error result' do
          call_action
          expect(assigns[:result]).to eq({ success: false, message: I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe})
        end
      end
      describe 'when the `@transaction_id` is present' do
        before do
          allow(transaction_id_response).to receive(:[]).with(:transaction_id).and_return(transaction_id)
        end
        it 'assigns `@mcu_type`' do
          call_action
          expect(assigns[:mcu_type]).to eq(mcu_type)
        end
        it 'assigns `@pledge_type`' do
          call_action
          expect(assigns[:pledge_type]).to eq(pledge_type)
        end
        it 'assigns `@program_type`' do
          call_action
          expect(assigns[:program_type]).to eq(program_type.upcase)
        end
        describe 'getting the server info' do
          let(:cache_key) { double('cache key') }
          let(:cache_expiry) { double('cache expiry') }
          let(:server_info) { double('server info') }
          before do
            allow(CacheConfiguration).to receive(:key).with(:mcu_server_info).and_return(cache_key)
            allow(CacheConfiguration).to receive(:expiry).with(:mcu_server_info).and_return(cache_expiry)
            allow(Rails.cache).to receive(:fetch).and_return(server_info)
          end
          it 'gets the server info from the cache' do
            expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: cache_expiry).and_yield
            call_action
          end
          describe 'a cache miss' do
            before do
              allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: cache_expiry).and_yield
            end
            it 'calls for the server info' do
              expect(member_balance_service).to receive(:mcu_server_info)
              call_action
            end
          end
          describe 'when the server info is `nil`' do
            before do
              allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: cache_expiry).and_return(nil)
            end
            it 'logs the error message' do
              expect(subject.logger).to receive(:error).with('No server info returned from the MCM message bus')
              call_action
            end
            it 'sets the error result' do
              call_action
              expect(assigns[:result]).to eq({ success: false, message: I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe})
            end
          end
        end
        describe 'when the server info is not `nil`' do
          before do
            allow(member_balance_service).to receive(:mcu_server_info).and_return(server_info)
          end
          describe 'when in production' do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end
            it 'gets the current time' do
              expect(Time.zone).to receive(:now)
              call_action
            end
            it 'replaces spaces with underscores in the original filename' do
              expect(original_filename).to receive(:gsub).with(' ', '_')
              call_action
            end
            it 'starts the sftp session' do
              expect(Net::SFTP).to receive(:start).with(hostname, svc_account_username, password: svc_account_password)
              call_action
            end
            it 'creates the remote path fragment directory via sftp' do
              expect(sftp).to receive(:mkdir).with(remote_path_fragment)
              call_action
            end
            it 'creates the remote path fragment including the year' do
              expect(sftp).to receive(:mkdir).with(remote_path_fragment_with_year)
              call_action
            end
            it 'creates the remote path fragment including the year and month' do
              expect(sftp).to receive(:mkdir).with(remote_path_fragment_with_year_and_month)
              call_action
            end
            it 'gets the `path` from the uploaded file' do
              expect(file).to receive(:path)
              call_action
            end
            it 'uploads the file' do
              expect(sftp).to receive(:upload!).with(local_path, remote_path)
              call_action
            end
            describe 'handling an SFTP execption' do
              let(:message) { "Failed to SFTP #{local_path} to #{remote_path}. Reason: sftp exception" } 
              before { allow(sftp).to receive(:upload!).and_raise Exception.new('sftp exception') }
              it 'logs the exception' do
                expect(subject.logger).to receive(:error).with(message)
                call_action
              end
              it 'sets a failure message' do
                call_action
                expect(assigns[:result]).to eq({ success: false, message: I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe})
              end
            end
            it 'does not raise an SFTP exception' do
              expect{ call_action }.not_to raise_error
            end
          end
        end
        it 'calls `mcu_upload_file` with the appropriate arguments' do
          expect(member_balance_service).to receive(:mcu_upload_file).with(transaction_id,
                                                                           mcu_type, 
                                                                           program_type.upcase, 
                                                                           username,
                                                                           "",
                                                                           archive_dir)
          call_action
        end
        it 'assigns `@result` to the result of `mcu_upload_file`' do
          call_action
          expect(assigns[:result]).to eq(result)
        end
        describe 'when the `mcu_upload_file` fails' do
          let(:error_result) { { success: false, message: 'error' } }
          before do
            allow(member_balance_service).to receive(:mcu_upload_file).and_return(error_result)
          end
          it 'logs the error message' do
            expect(subject.logger).to receive(:error).with("MCU upload failed. Reason: error")
            call_action
          end
          it 'sets the error result' do
            allow(controller).to receive(:collateral_operations_email).and_return(collateral_operations_email)
            allow(controller).to receive(:collateral_operations_phone_number).and_return(collateral_operations_phone_number)
            call_action
            expect(assigns[:result]).to eq({ success: false, message: I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe})
          end
        end
      end
    end
  end

  describe 'private methods' do
    describe '`translated_mcu_transaction`' do
      let(:transaction) {{
        mcuType: described_class::MCU_TYPE_MAPPING.keys.sample,
        pledge_type: described_class::PLEDGE_TYPE_MAPPING.keys.sample,
        program_type: described_class::PROGRAM_TYPE_MAPPING.keys.sample,
        status: described_class::STATUS_MAPPING.keys.sample
      }}
      let(:call_method) { subject.send(:translated_mcu_transaction, transaction) }
      it 'returns nil if passed nil' do
        expect(subject.send(:translated_mcu_transaction, nil)).to be nil
      end
      [
        {
          attr: :mcuType,
          const_name: 'MCU_TYPE_MAPPING',
          const: described_class::MCU_TYPE_MAPPING
        },
        {
          attr: :pledge_type,
          const_name: 'PLEDGE_TYPE_MAPPING',
          const: described_class::PLEDGE_TYPE_MAPPING
        },
        {
          attr: :program_type,
          const_name: 'PROGRAM_TYPE_MAPPING',
          const: described_class::PROGRAM_TYPE_MAPPING
        },
        {
          attr: :status,
          const_name: 'STATUS',
          const: described_class::STATUS_MAPPING
        },
      ].each do |translation|
        it "sets `translated_#{translation[:attr]}` to the value of the `#{translation[:attr]}` key found in `#{translation[:const_name]}`" do
          expect(call_method["translated_#{translation[:attr]}"]).to eq(translation[:const][transaction[translation[:attr]]])
        end
        it "does not set `translated_#{translation[:attr]}` if there is no `#{translation[:attr]}` value in the passed transaction" do
          transaction.delete(translation[:attr])
          expect(call_method["translated_#{translation[:attr]}"]).to be nil
        end
      end
      describe 'the `error_percentage` attribute' do
        let(:numberOfLoans) { rand(100..999) }
        let(:numberOfErrors) { numberOfLoans - rand(1..75) }
        let(:error_percentage) { call_method[:error_percentage] }
        it 'is not set if there is no `numberOfLoans` value in the passed transaction' do
          expect(error_percentage).to be nil
        end
        context 'when there is a `numberOfLoans` value in the passed transaction' do
          before { transaction[:numberOfLoans] = numberOfLoans }

          it 'is zero if there is no `numberOfErrors` value in the passed transaction' do
            expect(error_percentage).to eq(0)
          end

          context 'when there is a `numberOfErrors` value in the passed transaction' do
            before { transaction[:numberOfErrors] = numberOfErrors }

            it 'is the quotient of the `numberOfErrors` divided by the `numberOfLoans` times 100' do
              expect(error_percentage).to eq((numberOfErrors.to_f / numberOfLoans.to_f) * 100)
            end
          end
        end
      end
    end
  end
end