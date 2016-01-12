require 'rails_helper'
include CustomFormattingHelper

RSpec.describe ResourcesController, type: :controller do
  login_user

  describe 'GET guides' do
    it_behaves_like 'a user required action', :get, :guides
    it 'should render the guides view' do
      get :guides
      expect(response.body).to render_template('guides')
    end
  end

  describe 'GET business_continuity' do
    it_behaves_like 'a user required action', :get, :guides
    it 'should render the guides view' do
      get :business_continuity
      expect(response.body).to render_template('business_continuity')
    end
  end

  describe 'GET capital_plan' do
    it_behaves_like 'a user required action', :get, :capital_plan
    it 'should render the capital plan view' do
      get :capital_plan
      expect(response.body).to render_template('capital_plan')
    end
  end

  describe 'GET forms' do
    it_behaves_like 'a user required action', :get, :forms
    it 'should render the guides view' do
      get :forms
      expect(response.body).to render_template('forms')
    end
    [
      :agreement_rows, :signature_card_rows, :wire_transfer_rows, :capital_stock_rows,
      :website_access_rows, :credit_rows, :lien_real_estate_rows, :lien_other_rows,
      :specific_identification_rows, :deposits_rows, :securities_rows, :loan_document_rows,
      :creditor_relationship_rows
      ].each do |var|
        it "should assign `@#{var}`" do
          get :forms
          expect(assigns[var]).to be_present
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
      'xtra_agreement' => 'mpf-xtra-agreement-for-access-to-fannie-mae-du-only.pdf',
      'xtra_addendum_mpf' => 'mpf-xtra-addendum-servicing-retained.pdf',
      'xtra_addendum_servcer_account' => 'mpf-xtra-PI-custodial-account-agreement-mpf-bank.pdf',
      'xtra' => 'mpf-xtra-TI-custodial-account-agreement.pdf',
      'xtra_addendum_mpf_released' => 'mpf-xtra-addendum-servicing-released.pdf',
      'direct_agreement' => 'mpf-direct-addendum-to-pfi-agreement.pdf',
      'direct_questionnaire' => 'mpf-direct-operations-questionnaire.pdf'
    }
    [
      2117, 2349, 2127, 2177, 1465, 1694, 2136, 2065, 2066, 2108, 2067, 2153, 2068, 2070,
      2071, 2065, 2109, 1685, 2239, 2238, 2160, 2228, 2051, 2192, 1465, 2215, 2161, 2237,
      2281, 2242, 2241, 2243, 2202, 2200, 2249, 1547, 2204, 1722, 449, 1227, 2143, 2194
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
    
    it_behaves_like 'a user required action', :get, :fee_schedules
    it 'fetches fee schedule info from the FeeService' do
      expect(fee_service).to receive(:fee_schedules)
      fee_schedules
    end
    it 'raises an error if the FeeService returns nil' do
      allow(fee_service).to receive(:fee_schedules).and_return(nil)
      expect{fee_schedules}.to raise_error
    end
    
    describe 'letters of credit tables' do
      let(:loc_hash) { double('hash of loc data', :[] => fee_subhash) }
      before { allow(fee_service_data).to receive(:[]).with(:letters_of_credit).and_return(loc_hash) }
      
      describe '@annual_maintenance_charge_table' do
        let(:annual_maintenance_charge_hash) { double('a hash of annual maintenance charge data', :[] => fee_subhash) }
        before do 
          allow(loc_hash).to receive(:[]).with(:annual_maintenance_charge).and_return(annual_maintenance_charge_hash)
          allow(annual_maintenance_charge_hash).to receive(:[]).with(:minimum_annual_fee).and_return(whole_dollar_amount)
          [:cip_ace, :agency_deposits, :other_purposes].each do |key|
            allow(annual_maintenance_charge_hash).to receive(:[]).with(key).and_return(basis_point)
          end
        end
        
        it 'sets @annual_maintenance_charge_table to the result of passing annual_maintenance_charge_rows into the `fee_schedule_table_hash` method' do
          annual_maintenance_charge_rows = [
            [:minimum_annual_fee, whole_dollar_amount, :currency_whole],
            [:cip_ace, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)],
            [:agency_deposits, I18n.t('resources.fee_schedules.basis_point_per_annum', basis_point: basis_point)],
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
          [:agency_deposits, :other_purposes].each do |key|
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
          [:agency_deposits, :other_purposes].each do |key|
            allow(amendment_fee_hash).to receive(:[]).with(key).and_return(whole_dollar_amount)
          end
        end

        it 'sets @amendment_fee_table to the result of passing amendment_fee_rows into the `fee_schedule_table_hash` method' do
          amendment_fee_rows = [
            [:increase_extension],
            [:agency_deposits, whole_dollar_amount, :currency_whole],
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

  describe 'GET membership_overview' do
    it_behaves_like 'a user required action', :get, :membership_overview
    it 'should render the guides view' do
      get :membership_overview
      expect(response.body).to render_template('membership_overview')
    end
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
      expect{subject.send(:fee_schedule_table_hash, nil)}.to raise_error
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
end
