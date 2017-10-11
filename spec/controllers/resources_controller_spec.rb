require 'rails_helper'
include CustomFormattingHelper
include ContactInformationHelper
include ActionView::Helpers::UrlHelper
include ResourceHelper

RSpec.describe ResourcesController, type: :controller do
  login_user

  describe 'GET guides' do
    let(:member_id) { rand(1000..9999) }
    let(:call_action) { get :guides }
    before do
      allow(controller).to receive(:current_member_id).and_return(member_id)
    end

    it_behaves_like 'a controller action with an active nav setting', :guides, :resources
    it_behaves_like 'a user required action', :get, :guides
    it 'renders the guides view' do
      call_action
      expect(response.body).to render_template('guides')
    end
    context "when the `content-management-system` feature is enabled" do
      let(:cms) { instance_double(ContentManagementService) }
      let(:last_revised_date) { instance_double(Date) }
      let(:credit_guide) { instance_double(Cms::Guide, last_revised_date: nil) }
      let(:collateral_guide) { instance_double(Cms::Guide, last_revised_date: nil) }
      before do
        allow(controller).to receive(:feature_enabled?).with('content-management-system').and_return(true)
        allow(ContentManagementService).to receive(:new).and_return(cms)
        allow(Cms::Guide).to receive(:new)
      end

      it 'creates a new instance of `ContentManagementService` with the member id and request' do
        expect(ContentManagementService).to receive(:new).with(member_id, request).and_return(cms)
        call_action
      end
      it 'creates a new instance of `Cms::Guide` with the the member id, request, credit guide cms key and the cms instance' do
        expect(Cms::Guide).to receive(:new).with(member_id, request, :credit_guide, cms)
        call_action
      end
      it 'sets `@credit_guide` to the instance of `Cms::Guide` created with the `credit_guide` key' do
        allow(Cms::Guide).to receive(:new).with(anything, anything, :credit_guide, anything).and_return(credit_guide)
        call_action
        expect(assigns[:credit_guide]).to eq(credit_guide)
      end
      it 'sets `@credit_last_updated` to the result of calling `last_revised_date` on the credit `Cms::Guide` instance' do
        allow(Cms::Guide).to receive(:new).with(anything, anything, :credit_guide, anything).and_return(credit_guide)
        allow(credit_guide).to receive(:last_revised_date).and_return(last_revised_date)
        call_action
        expect(assigns[:credit_last_updated]).to eq(last_revised_date)
      end
      it 'creates a new instance of `Cms::Guide` with the the member id, request, collateral guide cms key and the cms instance' do
        expect(Cms::Guide).to receive(:new).with(member_id, request, :collateral_guide, cms)
        call_action
      end
      it 'sets `@collateral_guide` to the instance of `Cms::Guide` created with the `collateral_guide` key' do
        allow(Cms::Guide).to receive(:new).with(anything, anything, :collateral_guide, anything).and_return(collateral_guide)
        call_action
        expect(assigns[:collateral_guide]).to eq(collateral_guide)
      end
      it 'sets `@collateral_last_updated` to the result of calling `last_revised_date` on the collateral `Cms::Guide` instance' do
        allow(Cms::Guide).to receive(:new).with(anything, anything, :collateral_guide, anything).and_return(collateral_guide)
        allow(collateral_guide).to receive(:last_revised_date).and_return(last_revised_date)
        call_action
        expect(assigns[:collateral_last_updated]).to eq(last_revised_date)
      end
    end
    context "when the `content-management-system` feature is not enabled" do
      before { allow(controller).to receive(:feature_enabled?).with('content-management-system').and_return(false) }
      it 'sets `@credit_last_updated` to April 7, 2016' do
        call_action
        expect(assigns[:credit_last_updated]).to eq(Date.new(2016, 4, 7))
      end
      it 'sets `@collateral_last_updated` to July 28, 2017' do
        call_action
        expect(assigns[:collateral_last_updated]).to eq(Date.new(2017, 7, 28))
      end
    end
  end

  describe 'GET business_continuity' do
    it_behaves_like 'a controller action with an active nav setting', :business_continuity, :resources
    it_behaves_like 'a user required action', :get, :business_continuity
    it 'should render the guides view' do
      get :business_continuity
      expect(response.body).to render_template('business_continuity')
    end
  end

  describe 'GET capital_plan' do
    it_behaves_like 'a controller action with an active nav setting', :capital_plan, :resources
    it_behaves_like 'a user required action', :get, :capital_plan
    it 'should render the capital plan view' do
      get :capital_plan
      expect(response.body).to render_template('capital_plan')
    end
  end

  describe 'GET forms' do
    let(:link) { double(String) }
    let(:call_action) { get :forms }
    before do
      allow(subject).to receive(:feature_enabled?).and_call_original
      allow(subject).to receive(:docusign_link)
      allow(subject).to receive(:resources_download_path)
    end
    it_behaves_like 'a controller action with an active nav setting', :forms, :resources
    it_behaves_like 'a user required action', :get, :forms
    it 'should render the guides view' do
      get :forms
      expect(response.body).to render_template('forms')
    end
    [:agreement_rows, :signature_card_rows, :wire_transfer_rows, :capital_stock_rows,
    :website_access_rows, :credit_rows, :lien_real_estate_rows, :lien_other_rows,
    :specific_identification_rows, :deposits_rows, :loan_document_rows,
    :creditor_relationship_rows
    ].each do |var|
      it "should assign `@#{var}`" do
        call_action
        expect(assigns[var]).to be_present
      end
    end
    it 'assigns @securities_rows when the `securities-hide-forms` feature is disabled' do
      allow(subject).to receive(:feature_enabled?).with('securities-hide-forms').and_return(false)
      call_action
      expect(assigns[:securities_rows]).to be_present
    end
    it 'does not assign @securities_rows when the `securities-hide-forms` feature is enabled' do
      allow(subject).to receive(:feature_enabled?).with('securities-hide-forms').and_return(true)
      call_action
      expect(assigns[:securities_rows]).to_not be_present
    end
    describe '@website_access_rows' do
      [
        {
          title: I18n.t('resources.forms.authorizations.website.access_manager'),
          form_number: 2160,
          feature: 'resources-access-manager',
          docusign_link_key: :member_access_manager,
          pdf_link_key: :form_2160
        },
        {
          title: I18n.t('resources.forms.authorizations.website.securid'),
          form_number: 2228,
          feature: 'resources-token',
          docusign_link_key: :member_token_request,
          pdf_link_key: :form_2228
        }
      ].each_with_index do |form, i|
        describe "the `#{form[:title]}` form" do
          it 'has the correct title' do
            call_action
            expect(assigns[:website_access_rows][i][:title]).to eq(form[:title])
          end
          it "has a form_number of `#{form[:form_number]}`" do
            call_action
            expect(assigns[:website_access_rows][i][:form_number]).to eq(form[:form_number])
          end
          describe "when the `#{form[:feature]}` feature is enabled" do
            before { allow(subject).to receive(:feature_enabled?).with(form[:feature]).and_return(true) }
            it 'has an access manager form with the correct `docusign_link`' do
              allow(subject).to receive(:docusign_link).with(form[:docusign_link_key]).and_return(link)
              call_action
              expect(assigns[:website_access_rows][i][:docusign_link]).to eq(link)
            end
            it 'does not have a `pdf_link`' do
              call_action
              expect(assigns[:website_access_rows][i].keys).not_to include(:pdf_link)
            end
          end
          describe "when the `#{form[:feature]}` feature is disabled" do
            before { allow(subject).to receive(:feature_enabled?).with(form[:feature]).and_return(false) }
            it 'has an access manager form with the correct `pdf_link`' do
              allow(subject).to receive(:resources_download_path).with(file: form[:pdf_link_key]).and_return(link)
              call_action
              expect(assigns[:website_access_rows][i][:pdf_link]).to eq(link)
            end
            it 'does not have a `docusign_link`' do
              call_action
              expect(assigns[:website_access_rows][i].keys).not_to include(:docusign_link)
            end
          end
        end
      end
    end
  end

  describe 'GET download' do
    it_behaves_like 'a user required action', :get, :download, file: 'foo'
    it 'should raise `ActionController::MissingFile` if an unknown file is requested' do
      expect { get :download, file: 'foo' }.to raise_error(ActionController::MissingFile)
    end
    it 'should raise `ActionController::MissingFile` if an unknown form is requested' do
      expect { get :download, file: 'form_0001' }.to raise_error(ActionController::MissingFile)
    end
    context 'when the `content-management-system` feature is disabled' do
      before { allow(subject).to receive(:feature_enabled?).with('content-management-system').and_return(false) }

      file_mapping = {
        'creditguide' => 'creditguide.pdf',
        'collateralguide' => 'collateralguide.pdf',
        'collateralreviewguide' => 'mortgage-loan-collateral-field-review-process.pdf',
        'corporation_assignment' => 'Corporate_Assignment.doc',
        'credit_union_amendment' => 'corporate-credit-union-amendment.docx',
        'credit_union_agreement' => 'subordination-agreement-credit-unions.pdf',
        'capitalplan' => 'capital-plan.pdf',
        'capitalplansummary' => 'capital-plan-summary.pdf',
        'pfi_agreement_resolution' => 'mpf-pfi-agreement-resolution.pdf',
        'delegation_of_authority' => 'mpf-delegation-of-authority.pdf',
        'delegation_of_authority_requests' => 'mpf-delegation-of-authority-requests-for-files-from-custodian.pdf',
        'delegation_of_authority_definitions' => 'mpf-delegation-of-authority-definitions.pdf',
        'pfi_agreement' => 'mpf-pfi-agreement.pdf',
        'pfi_application' => 'mpf-pfi-application.pdf',
        'mortgage_operations_questionnaire' => 'mpf-mortgage-operations-questionnaire.pdf',
        'mortgage_operations_questionnaire_addendum' => 'mpf-mortgage-operations-questionnaire-addendum.pdf',
        'mpf_fidelity' => 'mpf-fidelity-errors-omissions-insurance-worksheet-OG2.pdf',
        'anti_predatory' => 'mpf-anti-predatory-lending-questionnaire.pdf',
        'in_house' => 'mpf-in-house-QC-questionnaire.pdf',
        'collateral_file' => 'mpf-collateral-file-release-information.pdf',
        'post_closing' => 'mpf-post-closing-information.pdf',
        'servicer' => 'mpf-servicer-information.pdf',
        'servicer_account_remittance' => 'mpf-PI-custodial-account-agreement-SS-or-AA-single-remittance.pdf',
        'servicer_account_actual' => 'mpf-PI-custodial-account-agreement-AA.pdf',
        'servicer_account' => 'mpf-TI-custodial-account-agreement.pdf',
        'direct_gov' => 'mpf-government.pdf',
        'xtra_agreement' => 'mpf-xtra-agreement-for-access-to-fannie-mae-du-only.pdf',
        'xtra_addendum_mpf' => 'mpf-xtra-addendum-servicing-retained.pdf',
        'xtra_addendum_servcer_account' => 'mpf-xtra-PI-custodial-account-agreement-mpf-bank.pdf',
        'xtra' => 'mpf-xtra-TI-custodial-account-agreement.pdf',
        'xtra_addendum_mpf_released' => 'mpf-xtra-addendum-servicing-released.pdf',
        'direct_agreement' => 'mpf-direct-addendum-to-pfi-agreement.pdf',
        'direct_questionnaire' => 'mpf-direct-operations-questionnaire.pdf'
      }
      [
        2117, 2349, 2127, 2177, 1465, 1694, 2136, 2065, 2066, 2108, 2067, 2153, 2068,
        2071, 2065, 2109, 1685, 2238, 2160, 2228, 2051, 2192, 1465, 2215, 2161, 2237, 2281,
        2242, 2241, 2243, 2202, 2200, 2249, 1547, 2204, 1722, 449, 1227, 2143, 2194
      ].each do |form_number|
        file_mapping["form_#{form_number}"] = "fc#{form_number}.pdf"
      end
      file_mapping.each do |name, file|
        it "should send the file `#{file}` when `#{name}` is requested" do
          expect(subject).to receive(:send_file).with(Rails.root.join('private', file), filename: file).and_call_original
          get :download, file: name
        end
      end
    end
    context 'when the `content-management-system` feature is enabled' do
      let(:member_id) { double('member id') }
      let(:pdf_url) { instance_double(String) }
      let(:cms) { instance_double(ContentManagementService, get_pdf_url: pdf_url) }
      let(:file) { instance_double(File, close:nil )}
      before do
        allow(controller).to receive(:current_member_id).and_return(member_id)
        allow(subject).to receive(:feature_enabled?).with('content-management-system').and_return(true)
        allow(ContentManagementService).to receive(:new).and_return(cms)
        allow(controller).to receive(:open).and_return(file)
        allow(File).to receive(:read)
      end

      {
        'creditguide' => {filename: 'creditguide.pdf', cms_key: :credit_guide},
        'collateralguide' => {filename: 'collateralguide.pdf', cms_key: :collateral_guide}
      }.each do |param_name, options|
        context "when `#{param_name}` is requested" do
          let(:call_action) { get :download, file: param_name}

          it 'creates a new instance of the `ContentManagementService` with the member_id and request object' do
            expect(ContentManagementService).to receive(:new).with(member_id, request).and_return(cms)
            call_action
          end
          it "calls `get_pdf_url` on the instance of `ContentManagementService` with `#{options[:cms_key]}`" do
            expect(cms).to receive(:get_pdf_url).with(options[:cms_key])
            call_action
          end
          context 'when a url is returned' do
            let(:read_file) { double('file') }
            before do
              allow(File).to receive(:read).with(file).and_return(read_file)
            end
            it 'opens the returned url' do
              expect(controller).to receive(:open).with(pdf_url)
              call_action
            end
            it 'reads the data stream' do
              expect(File).to receive(:read).with(file)
              call_action
            end
            it 'calls `send_data` with the read data stream' do
              expect(controller).to receive(:send_data).with(read_file, any_args).and_call_original
              call_action
            end
            it "calls `send_data` with `#{options[:filename]}` as the filename" do
              expect(controller).to receive(:send_data).with(anything, hash_including(filename: options[:filename])).and_call_original
              call_action
            end
            it 'calls `send_data` with `application/pdf` as the `type`' do
              expect(controller).to receive(:send_data).with(anything, hash_including(type: 'application/pdf')).and_call_original
              call_action
            end
            it 'calls `send_data` with `attachment` as the `disposition`' do
              expect(controller).to receive(:send_data).with(anything, hash_including(disposition: 'attachment')).and_call_original
              call_action
            end
            it 'closes the file' do
              expect(file).to receive(:close)
              call_action
            end
          end
          context 'when a url is not returned' do
            before { allow(cms).to receive(:get_pdf_url).and_return(nil) }
            it 'raises an error' do
              expect{call_action}.to raise_error(ActionController::MissingFile)
            end
          end
        end
      end
    end
  end

  describe 'GET fee_schedules' do
    let(:fee_subhash) { double('a subhash of the fee schedules object', :[] => nil) }
    let(:fee_service_data) { double('the fee schedules object', :[] => fee_subhash) }
    let(:fee_schedules) { get :fee_schedules }
    let(:fee_service) { double('fee service instance') }
    let(:basis_point) { rand(1..99) }
    let(:par) { rand(1..1000) }
    let(:whole_dollar_amount) { rand(100..100000) }
    let(:dollar_amount) { rand(1..100) + rand() }
    let(:table_data) { double('hash representing table data') }
    before do
      allow(FeesService).to receive(:new).and_return(fee_service)
      allow(fee_service).to receive(:fee_schedules).and_return(fee_service_data)
      allow(fee_subhash).to receive(:[]).and_return(fee_subhash)
      allow(controller).to receive(:fee_schedule_table_hash)
    end

    it_behaves_like 'a controller action with an active nav setting', :fee_schedules, :resources
    it_behaves_like 'a user required action', :get, :fee_schedules
    it 'fetches fee schedule info from the FeeService' do
      expect(fee_service).to receive(:fee_schedules)
      fee_schedules
    end
    it 'raises an error if the FeeService returns nil' do
      allow(fee_service).to receive(:fee_schedules).and_return(nil)
      expect{fee_schedules}.to raise_error(StandardError)
    end

    describe 'letters of credit tables' do
      let(:loc_hash) { double('hash of loc data', :[] => fee_subhash) }
      before { allow(fee_service_data).to receive(:[]).with(:letters_of_credit).and_return(loc_hash) }

      describe '@annual_maintenance_charge_table' do
        let(:annual_maintenance_charge_hash) { double('a hash of annual maintenance charge data', :[] => fee_subhash) }
        before do
          allow(loc_hash).to receive(:[]).with(:annual_maintenance_charge).and_return(annual_maintenance_charge_hash)
          allow(annual_maintenance_charge_hash).to receive(:[]).with(:minimum_annual_fee).and_return(whole_dollar_amount)
          [:cip_ace, :agency_deposits, :agency_deposits_variable_balance, :other_purposes].each do |key|
            allow(annual_maintenance_charge_hash).to receive(:[]).with(key).and_return(basis_point)
          end
        end

        it 'sets @annual_maintenance_charge_table to the result of passing annual_maintenance_charge_rows into the `fee_schedule_table_hash` method' do
          annual_maintenance_charge_rows = [
            [:minimum_annual_fee, whole_dollar_amount, :currency_whole],
            [:cip_ace, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)],
            [:agency_deposits, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)],
            [:agency_deposits_variable_balance, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)],
            [:other_purposes, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(annual_maintenance_charge_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:annual_maintenance_charge_table]).to eq(table_data)
        end
      end

      describe '@issuance_fee_table' do
        let(:issuance_fee_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(loc_hash).to receive(:[]).with(:issuance_fee).and_return(issuance_fee_hash)
          [:agency_deposits, :agency_deposits_variable_balance, :other_purposes].each do |key|
            allow(issuance_fee_hash).to receive(:[]).with(key).and_return(whole_dollar_amount)
          end
          [:commercial_paper, :tax_exempt_bond].each do |key|
            allow(issuance_fee_hash).to receive(:[]).with(key).and_return(fee_subhash)
            allow(fee_subhash).to receive(:[]).with(:lower_limit).and_return(whole_dollar_amount)
            allow(fee_subhash).to receive(:[]).with(:upper_limit).and_return(whole_dollar_amount)
          end
        end

        it 'sets @issuance_fee_table to the result of passing issuance_fee_rows into the `fee_schedule_table_hash` method' do
          issuance_fee_rows = [
            [:agency_deposits, whole_dollar_amount, :currency_whole],
            [:agency_deposits_variable_balance, whole_dollar_amount, :currency_whole],
            [:other_purposes, whole_dollar_amount, :currency_whole],
            [:commercial_paper, I18n.t('resources.fee_schedules.price_range', lower: fhlb_formatted_currency_whole(whole_dollar_amount, html: false), upper: fhlb_formatted_currency_whole(whole_dollar_amount, html: false))],
            [:tax_exempt_bond, I18n.t('resources.fee_schedules.price_range', lower: fhlb_formatted_currency_whole(whole_dollar_amount, html: false), upper: fhlb_formatted_currency_whole(whole_dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(issuance_fee_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:issuance_fee_table]).to eq(table_data)
        end
      end

      describe '@draw_fee_table' do
        let(:draw_fee_hash) { double('a hash of draw fee data', :[] => fee_subhash) }
        before do
          allow(loc_hash).to receive(:[]).with(:draw_fee).and_return(whole_dollar_amount)
        end

        it 'sets @draw_fee_table to the result of passing draw_fee_rows into the `fee_schedule_table_hash` method' do
          draw_fee_rows = [
            [:draw_fee, whole_dollar_amount, :currency_whole]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(draw_fee_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:draw_fee_table]).to eq(table_data)
        end
      end

      describe '@amendment_fee_table' do
        let(:amendment_fee_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(loc_hash).to receive(:[]).with(:amendment_fee).and_return(amendment_fee_hash)
          [:agency_deposits, :agency_deposits_variable_balance, :other_purposes].each do |key|
            allow(amendment_fee_hash).to receive(:[]).with(key).and_return(whole_dollar_amount)
          end
        end

        it 'sets @amendment_fee_table to the result of passing amendment_fee_rows into the `fee_schedule_table_hash` method' do
          amendment_fee_rows = [
            [:increase_extension],
            [:agency_deposits, whole_dollar_amount, :currency_whole],
            [:agency_deposits_variable_balance, whole_dollar_amount, :currency_whole],
            [:other_purposes, whole_dollar_amount, :currency_whole]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(amendment_fee_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:amendment_fee_table]).to eq(table_data)
        end
      end
    end

    describe 'Securities Services tables' do
      let(:securities_hash) { double('hash of Securities Services data', :[] => fee_subhash) }
      before { allow(fee_service_data).to receive(:[]).with(:securities_services).and_return(securities_hash) }

      describe '@monthly_maintenance_table' do
        let(:monthly_maintenance_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(securities_hash).to receive(:[]).with(:monthly_maintenance).and_return(monthly_maintenance_hash)
          [:less_than_10, :between_10_and_24, :more_than_24].each do |key|
            allow(monthly_maintenance_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @monthly_maintenance_table to the result of passing monthly_maintenance_rows into the `fee_schedule_table_hash` method' do
          monthly_maintenance_rows = [
            [:less_than_10, I18n.t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:between_10_and_24, I18n.t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:more_than_24, I18n.t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(monthly_maintenance_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:monthly_maintenance_table]).to eq(table_data)
        end
      end

      describe '@monthly_securities_table' do
        let(:monthly_securities_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(securities_hash).to receive(:[]).with(:monthly_securities).and_return(monthly_securities_hash)
          allow(securities_hash).to receive(:[]).with(:euroclear).and_return(fee_subhash)
          allow(fee_subhash).to receive(:[]).with(:fee_per_par).and_return(dollar_amount)
          allow(fee_subhash).to receive(:[]).with(:per_par_amount).and_return(par)
          [:fed, :dtc, :physical].each do |key|
            allow(monthly_securities_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @monthly_securities_table to the result of passing monthly_securities_rows into the `fee_schedule_table_hash` method' do
          monthly_securities_rows = [
            [:fed, I18n.t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:dtc, I18n.t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:physical, I18n.t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:euroclear, I18n.t('resources.fee_schedules.par_by_lot', amount: fhlb_formatted_currency(dollar_amount, html: false), par: par)],
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(monthly_securities_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:monthly_securities_table]).to eq(table_data)
        end
      end

      describe '@security_transaction_table' do
        let(:security_transaction_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(securities_hash).to receive(:[]).with(:security_transaction).and_return(security_transaction_hash)
          [:fed, :dtc, :physical, :euroclear].each do |key|
            allow(security_transaction_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @security_transaction_table to the result of passing security_transaction_rows into the `fee_schedule_table_hash` method' do
          security_transaction_rows = [
            [:fed, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:dtc, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:physical, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:euroclear, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(security_transaction_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:security_transaction_table]).to eq(table_data)
        end
      end

      describe '@securities_services_miscellaneous_table' do
        let(:securities_services_miscellaneous_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(securities_hash).to receive(:[]).with(:miscellaneous).and_return(securities_services_miscellaneous_hash)
          [:all_income_disbursement, :pledge_status_change].each do |key|
            allow(securities_services_miscellaneous_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @securities_services_miscellaneous_table to the result of passing securities_services_miscellaneous_rows into the `fee_schedule_table_hash` method' do
          securities_services_miscellaneous_rows = [
            [:all_income_disbursement, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:pledge_status_change, I18n.t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:certificate_registration, I18n.t('global.footnote_indicator')],
            [:research_projects, I18n.t('global.footnote_indicator')],
            [:special_handling, I18n.t('global.footnote_indicator')]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(securities_services_miscellaneous_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:securities_services_miscellaneous_table]).to eq(table_data)
        end
      end
    end

    describe 'Wire Transfer and STA tables' do
      let(:sta_hash) { double('hash of Wire Transfer and STA data', :[] => fee_subhash) }
      before { allow(fee_service_data).to receive(:[]).with(:wire_transfer_and_sta).and_return(sta_hash) }

      describe '@domestic_outgoing_wires_table' do
        let(:domestic_outgoing_wires_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(sta_hash).to receive(:[]).with(:domestic_outgoing_wires).and_return(domestic_outgoing_wires_hash)
          [:telephone_repetitive, :telephone_non_repetitive, :drawdown_request, :standing_request].each do |key|
            allow(domestic_outgoing_wires_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @domestic_outgoing_wires_table to the result of passing domestic_outgoing_wires_rows into the `fee_schedule_table_hash` method' do
          domestic_outgoing_wires_rows = [
            [:telephone_request],
            [:telephone_repetitive, I18n.t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:telephone_non_repetitive, I18n.t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:drawdown_request, I18n.t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:standing_request, I18n.t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(domestic_outgoing_wires_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:domestic_outgoing_wires_table]).to eq(table_data)
        end
      end

      describe '@domestic_incoming_wires_table' do
        let(:domestic_incoming_wires_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before { allow(sta_hash).to receive(:[]).with(:domestic_incoming_wires).and_return(dollar_amount) }

        it 'sets @domestic_incoming_wires_table to the result of passing domestic_incoming_wires_rows into the `fee_schedule_table_hash` method' do
          domestic_incoming_wires_rows = [
            [:domestic_incoming_wires, I18n.t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(domestic_incoming_wires_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:domestic_incoming_wires_table]).to eq(table_data)
        end
      end

      describe '@overdraft_charges_table' do
        let(:overdraft_charges_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(sta_hash).to receive(:[]).with(:overdraft_charges).and_return(overdraft_charges_hash)
          allow(overdraft_charges_hash).to receive(:[]).with(:interest_rate).and_return(basis_point)
          allow(overdraft_charges_hash).to receive(:[]).with(:processing_fee).and_return(dollar_amount)
        end

        it 'sets @overdraft_charges_table to the result of passing overdraft_charges_rows into the `fee_schedule_table_hash` method' do
          overdraft_charges_rows = [
            [:interest_rate, I18n.t('resources.fee_schedules.interest_rate_overdraft', basis_points: basis_point)],
            [:processing_fee, I18n.t('resources.fee_schedules.amount_per_overdraft', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(overdraft_charges_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:overdraft_charges_table]).to eq(table_data)
        end
      end

      describe '@sta_miscellaneous_table' do
        let(:sta_miscellaneous_hash) { double('a hash of issuance fee data', :[] => fee_subhash) }
        before do
          allow(sta_hash).to receive(:[]).with(:miscellaneous).and_return(sta_miscellaneous_hash)
          [:photocopies, :special_account_research].each do |key|
            allow(sta_miscellaneous_hash).to receive(:[]).with(key).and_return(dollar_amount)
          end
        end

        it 'sets @sta_miscellaneous_table to the result of passing sta_miscellaneous_rows into the `fee_schedule_table_hash` method' do
          sta_miscellaneous_rows = [
            [:photocopies, I18n.t('resources.fee_schedules.amount_per_statement', amount: fhlb_formatted_currency(dollar_amount, html: false))],
            [:special_account_research, I18n.t('resources.fee_schedules.amount_per_hour', amount: fhlb_formatted_currency(dollar_amount, html: false))]
          ]
          allow(controller).to receive(:fee_schedule_table_hash).with(sta_miscellaneous_rows).and_return(table_data)
          fee_schedules
          expect(assigns[:sta_miscellaneous_table]).to eq(table_data)
        end
      end
    end
  end

  RSpec.shared_examples 'a resource membership action' do |action|
    let(:call_action) { get action }
    it_behaves_like 'a controller action with an active nav setting', action, :resources
    it_behaves_like 'a user required action', :get, action
    it "renders the #{action.to_s} view" do
      call_action
      expect(response.body).to render_template(action.to_s)
    end
  end

  RSpec.shared_examples 'a resource membership action with application forms tables' do |action, application_type|
    let(:processed_rows) { double('processed rows') }
    let(:call_action) { get action }

    it_behaves_like 'a resource membership action', action
    it "calls `application_table_rows` with the form id hash for the `#{application_type}`" do
      expect(controller).to receive(:application_table_rows).with(described_class::APPLICATION_FORM_IDS[application_type])
      call_action
    end
    it 'sets `@application_table_rows` to the result of calling `application_table_rows`' do
      allow(controller).to receive(:application_table_rows).and_return(processed_rows)
      call_action
      expect(assigns[:application_table_rows]).to eq(processed_rows)
    end
  end

  describe 'GET :membership_overview' do
    it_behaves_like 'a resource membership action', :membership_overview
  end

  describe 'GET :membership_application' do
    it_behaves_like 'a resource membership action', :membership_application
  end

  describe 'GET :commercial_application' do
    it_behaves_like 'a resource membership action with application forms tables', :commercial_application, :commercial
  end

  describe 'GET :community_development_application' do
    it_behaves_like 'a resource membership action with application forms tables', :community_development_application, :community_development
  end

  describe 'GET :credit_union_application' do
    it_behaves_like 'a resource membership action with application forms tables', :credit_union_application, :credit_union
  end

  describe 'GET :insurance_company_application' do
    it_behaves_like 'a resource membership action with application forms tables', :insurance_company_application, :insurance_company
  end

  describe 'the `fee_schedule_table_hash` private method' do
    let(:translation) { double('I18n translation', to_s: 'foo') }
    let(:value) { double('a table cell value') }
    let(:type) { double('a table cell type') }
    let(:translation_2) { double('I18n translation', to_s: 'bar') }
    let(:value_2) { double('a table cell value') }
    let(:type_2) { double('a table cell type') }
    let(:rows) { [[translation, value, type], [translation_2, value_2, type_2]] }
    let(:call_method) { subject.send(:fee_schedule_table_hash, rows) }
    before do
      allow(subject).to receive(:t)
    end
    it 'raises an error if passed nil' do
      expect{subject.send(:fee_schedule_table_hash, nil)}.to raise_error(ArgumentError)
    end
    it 'returns a hash with a :rows attribute that is an array' do
      expect(call_method[:rows]).to be_kind_of(Array)
    end
    describe 'the :rows attribute' do
      before do
        allow(subject).to receive(:t).with("resources.fee_schedules.foo").and_return(translation)
        allow(subject).to receive(:t).with("resources.fee_schedules.bar").and_return(translation_2)
      end
      it 'returns a properly formatted column object for each given row' do
        table_data = {
          rows: [
            {
              columns: [
                {value: translation},
                {value: value, type: type}
              ]
            },
            {
              columns: [
                {value: translation_2},
                {value: value_2, type: type_2}
              ]
            }
          ]
        }
        expect(call_method).to eq(table_data)
      end
      it 'returns a column object with a blank value and type if only passed the translation argument' do
        table_data = {
          rows: [
            {
              columns: [
                {value: translation},
                {value: nil, type: nil}
              ]
            }
          ]
        }
        expect(subject.send(:fee_schedule_table_hash, [[translation]])).to eq(table_data)
      end
      it 'returns a column object with a blank type if only passed the translation and value arguments' do
        table_data = {
          rows: [
            {
              columns: [
                {value: translation},
                {value: value, type: nil}
              ]
            }
          ]
        }
        expect(subject.send(:fee_schedule_table_hash, [[translation, value]])).to eq(table_data)
      end
    end
  end

  describe 'private methods' do
    describe 'docusign_link' do
      let(:form) { double('form name', to_s: nil) }
      let(:user) { instance_double(User) }
      let(:member_id) { instance_double(Numeric) }
      let(:make_request) { subject.send(:docusign_link, form) }
      let(:docusign_service_link_subhash) { double(Hash, :[] => nil) }
      let(:docusign_service_link) { double(Hash, :[] => docusign_service_link_subhash) }
      let(:docusign_service) { double(DocusignService) }
      before do
        allow(DocusignService).to receive(:new).and_return(docusign_service)
        allow(docusign_service).to receive(:get_url).and_return(docusign_service_link)
      end
      it 'converts the form name to a string' do
        expect(form).to receive(:to_s)
        make_request
      end
      it 'calls `get_url` on the DocusignService instance with the form name as a string' do
        allow(form).to receive(:to_s).and_return(form)
        expect(docusign_service).to receive(:get_url).with(form, any_args)
        make_request
      end
      it 'calls `get_url` on the DocusignService instance with the current user' do
        allow(subject).to receive(:current_user).and_return(user)
        expect(docusign_service).to receive(:get_url).with(anything, user, anything)
        make_request
      end
      it 'calls `get_url` on the DocusignService instance with the member id' do
        allow(subject).to receive(:current_member_id).and_return(member_id)
        expect(docusign_service).to receive(:get_url).with(anything, anything, member_id)
        make_request
      end
      it 'returns link info from the DocusignService' do
        make_request
        expect(make_request).to eq(docusign_service_link_subhash.to_s)
      end
      it 'raises an error if the DocusignService returns nil' do
        allow(docusign_service).to receive(:get_url).and_return(nil)
        expect{make_request}.to raise_error(/encountered nil/i)
      end
    end

    describe '`form_description_from_id`' do
      let(:form_id) { SecureRandom.hex }
      let(:translation) { instance_double(String, html_safe: nil) }
      let(:call_method) { controller.send(:form_description_from_id, form_id) }

      [2104, 2112, 2178].each do |form_id|
        context "when the form_id is `#{form_id}`" do
          let(:form_id) { form_id }
          it "returns the proper description for the form with id `#{form_id}`" do
            expect(call_method).to eq(I18n.t("resources.membership.forms.id_#{form_id.to_s}.description_html", link: link_to(ContactInformationHelper::MEMBERSHIP_EMAIL, membership_email)))
          end
        end
      end
      context 'when the form_id is `2136`' do
        let(:form_id) { 2136 }
        it 'returns the proper description for the form with id `2136`' do
          expect(call_method).to eq(I18n.t("resources.membership.forms.id_#{form_id.to_s}.description_html", download_link: link_to_download_resource(I18n.t('resources.membership.forms.id_2135.title'), resources_download_path(file: :form_2135))))
        end
      end
      context 'when the form_id is `2349`' do
        let(:form_id) { 2349 }
        it 'returns the proper description for the form with id `2349`' do
          expect(call_method).to eq(I18n.t("resources.membership.forms.id_#{form_id.to_s}.description_html", download_link: link_to_download_resource(I18n.t('resources.membership.forms.id_2127.title'), resources_download_path(file: :form_2127))))
        end
      end
      context 'when the form_id is `1973`' do
        let(:form_id) { 1973 }
        it 'returns the proper description for the form with id `1973`' do
          expect(call_method).to eq(I18n.t("resources.membership.forms.id_1973.description_html", link: link_to(ContactInformationHelper::MEMBERSHIP_EMAIL, membership_email)))
        end
      end
      context 'when the the form_id is not explicitly called out in the case statement' do
        it 'calls the I18n localization method with a string containing the form id' do
          expect(controller).to receive(:t).with("resources.membership.forms.id_#{form_id}.description").and_return(translation)
          call_method
        end
        it 'returns the proper description for the provided form id' do
          allow(controller).to receive(:t).with("resources.membership.forms.id_#{form_id}.description").and_return(translation)
          allow(translation).to receive(:html_safe).and_return(translation)
          expect(call_method).to eq(translation)
        end
      end
      it 'ensures the translated string is html_safe' do
        allow(controller).to receive(:t).with("resources.membership.forms.id_#{form_id}.description").and_return(translation)
        expect(translation).to receive(:html_safe)
        call_method
      end
    end

    describe '`add_link_to_row`' do
      let(:row) { {form_number: SecureRandom.hex} }
      let(:call_method) { controller.send(:add_link_to_row, row) }
      context 'form_numbers without a link associated with them' do
        described_class::FORMS_WITHOUT_LINKS.each do |form_id|
          context "when the form_id is `#{form_id}`" do
            let(:row) { {form_number: form_id} }
            it 'does not add a link to the row' do
              expect(call_method[:pdf_link]).to be nil
            end
          end
        end
      end
      context 'when the form_number of the form is not `1973`' do
        let(:download_path) { instance_double(String) }
        it 'calls `resources_download_path` with an argument including the form_number of the row' do
          expect(controller).to receive(:resources_download_path).with(file: :"form_#{row[:form_number]}")
          call_method
        end
        it 'sets the `pdf_link` key of the row to the value returned by `resources_download_path`' do
          expect(controller).to receive(:resources_download_path).with(file: :"form_#{row[:form_number]}").and_return(download_path)
          call_method
          expect(row[:pdf_link]).to eq(download_path)
        end
      end
    end

    describe '`application_table_rows`' do
      before do
        allow(controller).to receive(:t)
        allow(controller).to receive(:form_description_from_id)
        allow(controller).to receive(:add_link_to_row) { |row| row}
      end
      it 'returns a hash with a key for each key it was passed' do
        keys = %w(a b c d e f g).sample(3)
        argument_hash = Hash[keys.collect{ |key| [key, []] }]
        expect(controller.send(:application_table_rows, argument_hash).keys).to eq(keys)
      end
      it 'contains a row for every form_id it is passed' do
        n = rand(2..5)
        form_ids = [1, 2, 3, 4, 5, 6, 7]
        argument_hash = {some_application_type: form_ids.sample(n)}
        expect(controller.send(:application_table_rows, argument_hash)[:some_application_type].length).to eq(n)
      end
      describe 'constructing a row from a form_id' do
        let(:form_id) { SecureRandom.hex }
        let(:title) { instance_double(String) }
        let(:description) { instance_double(String) }
        let(:call_method) { controller.send(:application_table_rows, {some_application_type: [form_id]}) }
        let(:row) { call_method[:some_application_type][0] }
        it 'uses the form_id when translating the title' do
          expect(controller).to receive(:t).with("resources.membership.forms.id_#{form_id.to_s}.title")
          call_method
        end
        it 'sets the `title` of the row to the result of the translation' do
          allow(controller).to receive(:t).with("resources.membership.forms.id_#{form_id.to_s}.title").and_return(title)
          expect(row[:title]).to eq(title)
        end
        it 'calls `form_description_from_id` with the form_id' do
          expect(controller).to receive(:form_description_from_id).with(form_id)
          call_method
        end
        it 'sets the `description` of the row to the result of `form_description_from_id`' do
          expect(controller).to receive(:form_description_from_id).with(form_id).and_return(description)
          expect(row[:description]).to eq(description)
        end
        it 'sets the `form_number` of the row to the form_id' do
          expect(row[:form_number]).to eq(form_id)
        end
        it 'calls `add_link_to_row` with the row' do
          allow(controller).to receive(:t).and_return(title)
          expect(controller).to receive(:form_description_from_id).and_return(description)
          processed_row = {title: title, description: description, form_number: form_id}
          expect(controller).to receive(:add_link_to_row).with(processed_row)
          call_method
        end
      end
    end
  end
end
