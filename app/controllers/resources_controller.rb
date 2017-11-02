class ResourcesController < ApplicationController
  include CustomFormattingHelper
  include ContactInformationHelper
  include ActionView::Helpers::UrlHelper
  include ResourceHelper

  APPLICATION_FORM_IDS = {
    commercial: {
      required: [2093, 2094, 2090, 2091, 2065, 2089, 2104, 2290],
      requested: [2117, 2136, 2160],
      optional: [1694, 1973, 1465, 2228],
      access: [2066, 2067, 2153, 2068, 2109, 2108]
    },
    community_development: {
      required: [2345, 2346, 2347, 2091, 2065, 2348],
      requested: [2349, 2136, 2160],
      optional: [1694, 1465, 2228],
      access: [2066, 2067, 2153, 2068, 2109, 2108]
    },
    credit_union: {
      required: [2138, 2139, 2090, 2091, 2065, 2099, 2112, 2290],
      requested: [2127, 2136, 2160],
      optional: [1694, 1973, 1465, 2228],
      access: [2066, 2067, 2153, 2068, 2109, 2108]
    },
    insurance_company: {
      required: [2170, 2171, 2090, 2091, 2065, 2178, 2290],
      requested: [2177, 2136, 2160],
      optional: [1694, 1973, 1465, 2228],
      access: [2066, 2067, 2153, 2068, 2109, 2108]
    }
  }.freeze

  FORMS_WITHOUT_LINKS = [1973]

  FORM_ID_CMS_KEY_MAPPING = {
    449 => :pledge_of_securities,
    1227 => :securities_release_request,
    1465 => :letter_of_credit_reimbursement_agreement,
    1547 => :specific_identification_mcu_transmittal_letter,
    1685 => :authorization_repetitive_wire_instructions,
    1694 => :safekeeping_agreement,
    1722 => :pledge_of_time_deposit_account,
    1973 => :isda_master_agreement_schedule,
    2051 => :credit_application_cip_and_ace,
    2065 => :resolution_authorization_member_transactions,
    2066 => :authorization_entire_authority,
    2067 => :authorization_advances,
    2068 => :authorization_collateral,
    2071 => :authorization_money_market_transaction,
    2089 => :calculation_of_percent_requirement_commercial_banks,
    2090 => :certificate_of_applicant_commercial_banks,
    2091 => :resolution_membership_counsel_certification,
    2093 => :forms_and_exhibits_checklist_commercial_banks,
    2094 => :applicant_information_commercial_banks,
    2099 => :calculation_of_percent_requirement_credit_unions,
    2104 => :applicants_bank_stock_calculation_commercial_banks,
    2108 => :authorization_wire_transfer_services,
    2109 => :authorization_securities_services,
    2112 => :applicants_bank_stock_calculation_credit_unions,
    2117 => :advances_security_agreement_commercial_banks,
    2127 => :advances_security_agreement_credit_unions,
    2136 => :settlement_transaction_account_agreement,
    2138 => :forms_and_exhibits_checklist_credit_union,
    2139 => :applicant_information_credit_unions,
    2143 => :safekeeping_deposit_request,
    2153 => :authorization_affordable_housing_program,
    2160 => :authorization_portal_access_manager,
    2161 => :statement_of_authority_putable_advances,
    2170 => :forms_and_exhibits_checklist_insurance_companies,
    2171 => :applicant_information_insurance_companies,
    2177 => :advances_security_agreement_insurance_companies,
    2178 => :applicants_bank_stock_calculation_insurance_companies,
    2192 => :ace_application_sba_lenders,
    2194 => :safekeeping_release_request,
    2200 => :cfi_blanket_lien_collateral_release_request_certification,
    2202 => :cfi_blanket_lien_collateral_certification,
    2204 => :specific_identification_mcu_data_field_questionnaire,
    2215 => :statement_of_authority_advances_partial_prepayment,
    2228 => :authorization_securid_token_request,
    2237 => :blanket_lien_real_estate_pledging_reporting_designation,
    2238 => :authorization_capital_stock_redemption_notice,
    2241 => :blanket_lien_collateral_certification_credit_unions,
    2242 => :blanket_lien_collateral_eligibility_commercial_banks,
    2243 => :blanket_lien_mcu_notification_detailed_reporting,
    2249 => :specific_identification_mcu_data_transmission_set_up,
    2281 => :anti_predatory_lending_policy_certification_blanket_lien,
    2290 => :authorization_to_release_records_arizona,
    2345 => :forms_and_exhibits_checklist_community_development,
    2346 => :applicant_information_community_development,
    2347 => :certificate_of_applicant_community_development,
    2348 => :applicants_bank_stock_calculation_community_development,
    2349 => :advances_security_agreement_community_development
  }.freeze

  before_action do
    set_active_nav(:resources)
  end

  before_action only: [:forms, :commercial_application, :community_development_application, :credit_union_application, :insurance_company_application] do
    @cms_enabled = feature_enabled?('content-management-system')
    @cms = ContentManagementService.new(current_member_id, request) if @cms_enabled
  end

  # GET
  def guides
    if feature_enabled?('content-management-system')
      cms = ContentManagementService.new(current_member_id, request)
      @credit_guide = Cms::Guide.new(current_member_id, request, :credit_guide, cms)
      @collateral_guide = Cms::Guide.new(current_member_id, request, :collateral_guide, cms)
    end
    @credit_last_updated = @credit_guide.try(:last_revised_date) || Date.new(2016, 4, 7)
    @collateral_last_updated = @collateral_guide.try(:last_revised_date) || Date.new(2017, 7, 28)
  end

  # GET
  def forms
    @agreement_rows  = [
      {
        title: t('resources.forms.agreements.advances'),
        rows: [
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :advances_security_agreement_commercial_banks) : t('resources.forms.agreements.commercial_banks'),
            form_number: 2117,
            pdf_link: resources_download_path(file: :form_2117)
          },
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :advances_security_agreement_community_development) : t('resources.forms.agreements.community'),
            form_number: 2349,
            pdf_link: resources_download_path(file: :form_2349)
          },
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :advances_security_agreement_credit_unions) : t('resources.forms.agreements.credit_unions'),
            form_number: 2127,
            pdf_link: resources_download_path(file: :form_2127)
          },
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :advances_security_agreement_insurance_companies) : t('resources.forms.agreements.insurance'),
            form_number: 2177,
            pdf_link: resources_download_path(file: :form_2177)
          }
        ]
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :letter_of_credit_reimbursement_agreement) : t('resources.forms.agreements.letters_of_credit'),
        form_number: 1465,
        pdf_link: resources_download_path(file: :form_1465)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :safekeeping_agreement) : t('resources.forms.agreements.safekeeping'),
        form_number: 1694,
        pdf_link: resources_download_path(file: :form_1694)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :settlement_transaction_account_agreement) : t('resources.forms.agreements.settlement_transaction_account'),
        form_number: 2136,
        pdf_link: resources_download_path(file: :form_2136)
      }
    ]

    @signature_card_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :resolution_authorization_member_transactions) : t('resources.forms.authorizations.signature_cards.member_transactions'),
        form_number: 2065,
        pdf_link: resources_download_path(file: :form_2065)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_entire_authority) : t('resources.forms.authorizations.signature_cards.entire_authority'),
        form_number: 2066,
        pdf_link: resources_download_path(file: :form_2066)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_wire_transfer_services) : t('resources.forms.authorizations.signature_cards.wire_transfer'),
        form_number: 2108,
        pdf_link: resources_download_path(file: :form_2108)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_advances) : t('resources.forms.authorizations.signature_cards.advances'),
        form_number: 2067,
        pdf_link: resources_download_path(file: :form_2067)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_affordable_housing_program) : t('resources.forms.authorizations.signature_cards.affordable_housing'),
        form_number: 2153,
        pdf_link: resources_download_path(file: :form_2153)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_collateral) : t('resources.forms.authorizations.signature_cards.collateral'),
        form_number: 2068,
        pdf_link: resources_download_path(file: :form_2068)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_money_market_transaction) : t('resources.forms.authorizations.signature_cards.money_market'),
        form_number: 2071,
        pdf_link: resources_download_path(file: :form_2071)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_securities_services) : t('resources.forms.authorizations.signature_cards.securities_services'),
        form_number: 2109,
        pdf_link: resources_download_path(file: :form_2109)
      }
    ]

    @wire_transfer_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_repetitive_wire_instructions) : t('resources.forms.authorizations.wire_transfer.repetitive'),
        form_number: 1685,
        pdf_link: resources_download_path(file: :form_1685)
      }
    ]

    @capital_stock_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_capital_stock_redemption_notice) : t('resources.forms.authorizations.capital_stock.redemption'),
        form_number: 2238,
        pdf_link: resources_download_path(file: :form_2238)
      }
    ]

    access_manager_form = {
      title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_portal_access_manager) : t('resources.forms.authorizations.website.access_manager'),
      form_number: 2160
    }
    feature_enabled?('resources-access-manager') ? access_manager_form[:docusign_link] = docusign_link(:member_access_manager) : access_manager_form[:pdf_link] = resources_download_path(file: :form_2160)
    resource_token_form = {
      title: @cms_enabled ? forms_page_title_from_cms(@cms, :authorization_securid_token_request) : t('resources.forms.authorizations.website.securid'),
      form_number: 2228,
    }
    feature_enabled?('resources-token') ? resource_token_form[:docusign_link] = docusign_link(:member_token_request) : resource_token_form[:pdf_link] = resources_download_path(file: :form_2228)
    @website_access_rows = [access_manager_form, resource_token_form]

    @credit_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :credit_application_cip_and_ace) : t('resources.forms.credit.application'),
        form_number: 2051,
        pdf_link: resources_download_path(file: :form_2051)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :ace_application_sba_lenders) : t('resources.forms.credit.ace_application'),
        form_number: 2192,
        pdf_link: resources_download_path(file: :form_2192)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :letter_of_credit_reimbursement_agreement) : t('resources.forms.credit.reimbursement'),
        form_number: 1465,
        pdf_link: resources_download_path(file: :form_1465)
      },
      {
        title: t('resources.forms.credit.statement_of_authority'),
        rows: [
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :statement_of_authority_advances_partial_prepayment) : t('resources.forms.credit.prepayment_symmetry'),
            form_number: 2215,
            pdf_link: resources_download_path(file: :form_2215)
          },
          {
            title: @cms_enabled ? forms_page_title_from_cms(@cms, :statement_of_authority_putable_advances) : t('resources.forms.credit.putable_advances'),
            form_number: 2161,
            pdf_link: resources_download_path(file: :form_2161)
          }
        ]
      },
    ]

    @lien_real_estate_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :blanket_lien_real_estate_pledging_reporting_designation) : t('resources.forms.collateral.lien_real_estate.pledging'),
        form_number: 2237,
        pdf_link: resources_download_path(file: :form_2237)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :anti_predatory_lending_policy_certification_blanket_lien) : t('resources.forms.collateral.lien_real_estate.lending_policy'),
        form_number: 2281,
        pdf_link: resources_download_path(file: :form_2281)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :blanket_lien_collateral_eligibility_commercial_banks) : t('resources.forms.collateral.lien_real_estate.questionnaire_html').html_safe,
        form_number: 2242,
        pdf_link: resources_download_path(file: :form_2242)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :blanket_lien_collateral_certification_credit_unions) : t('resources.forms.collateral.lien_real_estate.certification'),
        form_number: 2241,
        pdf_link: resources_download_path(file: :form_2241)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :blanket_lien_mcu_notification_detailed_reporting) : t('resources.forms.collateral.lien_real_estate.notification'),
        form_number: 2243,
        pdf_link: resources_download_path(file: :form_2243)
      }
    ]

    @lien_other_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :cfi_blanket_lien_collateral_certification) : t('resources.forms.collateral.lien_other.certification'),
        form_number: 2202,
        pdf_link: resources_download_path(file: :form_2202)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :cfi_blanket_lien_collateral_release_request_certification) : t('resources.forms.collateral.lien_other.release'),
        form_number: 2200,
        pdf_link: resources_download_path(file: :form_2200)
      }
    ]

    @specific_identification_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :specific_identification_mcu_data_transmission_set_up) : t('resources.forms.collateral.specific_identification.transmission'),
        form_number: 2249,
        pdf_link: resources_download_path(file: :form_2249)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :specific_identification_mcu_transmittal_letter) : t('resources.forms.collateral.specific_identification.transmittal'),
        form_number: 1547,
        pdf_link: resources_download_path(file: :form_1547)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :specific_identification_mcu_data_field_questionnaire) : t('resources.forms.collateral.specific_identification.questionnaire'),
        form_number: 2204,
        pdf_link: resources_download_path(file: :form_2204)
      }
    ]

    @deposits_rows  = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :pledge_of_time_deposit_account) : t('resources.forms.collateral.deposits.pledge'),
        form_number: 1722,
        pdf_link: resources_download_path(file: :form_1722)
      }
    ]

    unless feature_enabled?('securities-hide-forms')
      @securities_rows = [
        {
          title: @cms_enabled ? forms_page_title_from_cms(@cms, :pledge_of_securities) : t('resources.forms.collateral.securities.pledge'),
          form_number: 449,
          pdf_link: resources_download_path(file: :form_449)
        },
        {
          title: @cms_enabled ? forms_page_title_from_cms(@cms, :securities_release_request) : t('resources.forms.collateral.securities.release'),
          form_number: 1227,
          pdf_link: resources_download_path(file: :form_1227)
        },
        {
          title: @cms_enabled ? forms_page_title_from_cms(@cms, :safekeeping_deposit_request) : t('resources.forms.collateral.securities.deposit'),
          form_number: 2143,
          pdf_link: resources_download_path(file: :form_2143)
        },
        {
          title: @cms_enabled ? forms_page_title_from_cms(@cms, :safekeeping_release_request) : t('resources.forms.collateral.securities.safekeeping_release'),
          form_number: 2194,
          pdf_link: resources_download_path(file: :form_2194)
        }
      ]
    end

    @loan_document_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :corporation_assignment_template) : t('resources.forms.collateral.loan_document.assignment'),
        word_link: resources_download_path(file: :corporation_assignment)
      }
    ]

    @creditor_relationship_rows = [
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :amendment_to_corporate_credit_union_security_agreement) : t('resources.forms.collateral.creditor_relationship.amendment'),
        word_link: resources_download_path(file: :credit_union_amendment)
      },
      {
        title: @cms_enabled ? forms_page_title_from_cms(@cms, :subordination_agreement_credit_unions) : t('resources.forms.collateral.creditor_relationship.agreement'),
        form_number: 2373,
        pdf_link: resources_download_path(file: :credit_union_agreement)
      }
    ]
  end

  # GET
  def download
    mime_type = 'application/pdf'
    case params[:file]
    when 'creditguide'
      cms_key = :credit_guide
      filename = 'creditguide.pdf'
    when 'collateralguide'
      cms_key = :collateral_guide
      filename = 'collateralguide.pdf'
    when 'collateralreviewguide'
      filename = 'mortgage-loan-collateral-field-review-process.pdf'
    when 'corporation_assignment'
      cms_key = :corporation_assignment_template
      filename = 'Corporate_Assignment.doc'
      mime_type = 'application/msword'
    when 'credit_union_amendment'
      cms_key = :amendment_to_corporate_credit_union_security_agreement
      filename = 'corporate-credit-union-amendment.docx'
      mime_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'credit_union_agreement'
      cms_key = :subordination_agreement_credit_unions
      filename = 'subordination-agreement-credit-unions.pdf'
    when 'capitalplan'
      filename = 'capital-plan.pdf'
    when 'capitalplansummary'
      filename = 'capital-plan-summary.pdf'
    when 'pfi_agreement_resolution'
      filename = 'mpf-pfi-agreement-resolution.pdf'
    when 'delegation_of_authority'
      filename = 'mpf-delegation-of-authority.pdf'
    when 'delegation_of_authority_requests'
      filename = 'mpf-delegation-of-authority-requests-for-files-from-custodian.pdf'
    when 'delegation_of_authority_definitions'
      filename = 'mpf-delegation-of-authority-definitions.pdf'
    when 'pfi_agreement'
      filename = 'mpf-pfi-agreement.pdf'
    when 'pfi_application'
      filename = 'mpf-pfi-application.pdf'
    when 'mortgage_operations_questionnaire'
      filename = 'mpf-mortgage-operations-questionnaire.pdf'
    when 'mortgage_operations_questionnaire_addendum'
      filename = 'mpf-mortgage-operations-questionnaire-addendum.pdf'
    when 'mpf_fidelity'
      filename = 'mpf-fidelity-errors-omissions-insurance-worksheet-OG2.pdf'
    when 'anti_predatory'
      filename = 'mpf-anti-predatory-lending-questionnaire.pdf'
    when 'in_house'
      filename = 'mpf-in-house-QC-questionnaire.pdf'
    when 'collateral_file'
      filename = 'mpf-collateral-file-release-information.pdf'
    when 'post_closing'
      filename = 'mpf-post-closing-information.pdf'
    when 'servicer'
      filename = 'mpf-servicer-information.pdf'
    when 'servicer_account_remittance'
      filename = 'mpf-PI-custodial-account-agreement-SS-or-AA-single-remittance.pdf'
    when 'servicer_account_actual'
      filename = 'mpf-PI-custodial-account-agreement-AA.pdf'
    when 'servicer_account'
      filename = 'mpf-TI-custodial-account-agreement.pdf'
    when 'xtra_agreement'
      filename = 'mpf-xtra-agreement-for-access-to-fannie-mae-du-only.pdf'
    when 'xtra_addendum_mpf'
      filename = 'mpf-xtra-addendum-servicing-retained.pdf'
    when 'xtra_addendum_servcer_account'
      filename = 'mpf-xtra-PI-custodial-account-agreement-mpf-bank.pdf'
    when 'xtra'
      filename = 'mpf-xtra-TI-custodial-account-agreement.pdf'
    when 'xtra_addendum_mpf_released'
      filename = 'mpf-xtra-addendum-servicing-released.pdf'
    when 'direct_agreement'
      filename = 'mpf-direct-addendum-to-pfi-agreement.pdf'
    when 'direct_questionnaire'
      filename = 'mpf-direct-operations-questionnaire.pdf'
    when 'direct_gov'
      filename = 'mpf-government.pdf'
    when /\Aform_(\d{3,4})\z/
      form_id = $1.to_i
      filename = "fc#{form_id}.pdf"
      if FORM_ID_CMS_KEY_MAPPING.keys.include?(form_id)
        cms_key = FORM_ID_CMS_KEY_MAPPING[form_id]
      end
    else
      raise ActionController::MissingFile
    end

    if feature_enabled?('content-management-system') && cms_key
      url = ContentManagementService.new(current_member_id, request).get_file_download_url(cms_key)
      if url
        begin
          data = open(url)
          send_data File.read(data),
                    filename: filename,
                    type: mime_type,
                    disposition: 'attachment'
        ensure
          data.close
        end
      else
        raise ActionController::MissingFile
      end
    else
      send_file Rails.root.join('private', filename), filename: filename
    end
  end

  def business_continuity
  end

  def capital_plan
  end

  def fee_schedules
    fees = FeesService.new(request).fee_schedules
    raise StandardError, "There has been an error and ResourcesController#fee_schedules has encountered nil. Check error logs." if fees.nil?
    # LOC - annual maintenace charge
    annual_maintenance_charge_root = fees[:letters_of_credit][:annual_maintenance_charge]
    annual_maintenance_charge_rows = [
      [:minimum_annual_fee, annual_maintenance_charge_root[:minimum_annual_fee], :currency_whole],
      [:cip_ace, t('resources.fee_schedules.basis_point_per_annum', basis_point: annual_maintenance_charge_root[:cip_ace])],
      [:agency_deposits, t('resources.fee_schedules.basis_point_per_annum', basis_point: annual_maintenance_charge_root[:agency_deposits])],
      [:agency_deposits_variable_balance, t('resources.fee_schedules.basis_point_per_annum', basis_point: annual_maintenance_charge_root[:agency_deposits_variable_balance])],
      [:other_purposes, t('resources.fee_schedules.basis_point_per_annum', basis_point: annual_maintenance_charge_root[:other_purposes])]
    ]
    @annual_maintenance_charge_table = fee_schedule_table_hash(annual_maintenance_charge_rows)

    # LOC - issuance fee
    issuance_fee_root = fees[:letters_of_credit][:issuance_fee]
    issuance_fee_rows = [
      [:agency_deposits, issuance_fee_root[:agency_deposits], :currency_whole],
      [:agency_deposits_variable_balance, issuance_fee_root[:agency_deposits_variable_balance], :currency_whole],
      [:other_purposes, issuance_fee_root[:other_purposes], :currency_whole],
      [:commercial_paper, t('resources.fee_schedules.price_range', lower: fhlb_formatted_currency_whole(issuance_fee_root[:commercial_paper][:lower_limit], html: false), upper: fhlb_formatted_currency_whole(issuance_fee_root[:commercial_paper][:upper_limit], html: false))],
      [:tax_exempt_bond, t('resources.fee_schedules.price_range', lower: fhlb_formatted_currency_whole(issuance_fee_root[:tax_exempt_bond][:lower_limit], html: false), upper: fhlb_formatted_currency_whole(issuance_fee_root[:tax_exempt_bond][:upper_limit], html: false))]
    ]
    @issuance_fee_table = fee_schedule_table_hash(issuance_fee_rows)

    # LOC - draw fee
    @draw_fee_table = fee_schedule_table_hash([[:draw_fee, fees[:letters_of_credit][:draw_fee], :currency_whole]])

    # LOC - amendment fee
    amendment_fee_root = fees[:letters_of_credit][:amendment_fee]
    amendment_fee_rows = [
      [:increase_extension],
      [:agency_deposits, amendment_fee_root[:agency_deposits], :currency_whole],
      [:agency_deposits_variable_balance, amendment_fee_root[:agency_deposits_variable_balance], :currency_whole],
      [:other_purposes, amendment_fee_root[:other_purposes], :currency_whole]
    ]
    @amendment_fee_table = fee_schedule_table_hash(amendment_fee_rows)

    # Securities Services - monthly maintenance
    monthly_maintenance_root = fees[:securities_services][:monthly_maintenance]
    monthly_maintenance_rows = [
      [:less_than_10, t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(monthly_maintenance_root[:less_than_10], html: false))],
      [:between_10_and_24, t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(monthly_maintenance_root[:between_10_and_24], html: false))],
      [:more_than_24, t('resources.fee_schedules.amount_per_month', amount: fhlb_formatted_currency(monthly_maintenance_root[:more_than_24], html: false))]
    ]
    @monthly_maintenance_table = fee_schedule_table_hash(monthly_maintenance_rows)

    # Securities Services - monthly securities
    monthly_securities_root = fees[:securities_services][:monthly_securities]
    monthly_securities_rows = [
      [:fed, t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(monthly_securities_root[:fed], html: false))],
      [:dtc, t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(monthly_securities_root[:dtc], html: false))],
      [:physical, t('resources.fee_schedules.item_by_lot', amount: fhlb_formatted_currency(monthly_securities_root[:physical], html: false))],
      [:euroclear, t('resources.fee_schedules.par_by_lot', amount: fhlb_formatted_currency(monthly_securities_root[:euroclear][:fee_per_par], html: false), par: monthly_securities_root[:euroclear][:per_par_amount])],
    ]
    @monthly_securities_table = fee_schedule_table_hash(monthly_securities_rows)

    # Securities Services - security transaction
    security_transaction_root = fees[:securities_services][:security_transaction]
    security_transaction_rows = [
      [:fed, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(security_transaction_root[:fed], html: false))],
      [:dtc, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(security_transaction_root[:dtc], html: false))],
      [:physical, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(security_transaction_root[:physical], html: false))],
      [:euroclear, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(security_transaction_root[:euroclear], html: false))]
    ]
    @security_transaction_table = fee_schedule_table_hash(security_transaction_rows)

    # Securities Services - miscellaneous
    securities_services_miscellaneous_root = fees[:securities_services][:miscellaneous]
    securities_services_miscellaneous_rows = [
      [:all_income_disbursement, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(securities_services_miscellaneous_root[:all_income_disbursement], html: false))],
      [:pledge_status_change, t('resources.fee_schedules.amount_per_item', amount: fhlb_formatted_currency(securities_services_miscellaneous_root[:pledge_status_change], html: false))],
      [:certificate_registration, t('global.footnote_indicator')],
      [:research_projects, t('global.footnote_indicator')],
      [:special_handling, t('global.footnote_indicator')]
    ]
    @securities_services_miscellaneous_table = fee_schedule_table_hash(securities_services_miscellaneous_rows)

    # Wire Transfer and STA - domestic outgoing wires
    domestic_outgoing_wires_root = fees[:wire_transfer_and_sta][:domestic_outgoing_wires]
    domestic_outgoing_wires_rows = [
      [:telephone_request],
      [:telephone_repetitive, t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(domestic_outgoing_wires_root[:telephone_repetitive], html: false))],
      [:telephone_non_repetitive, t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(domestic_outgoing_wires_root[:telephone_non_repetitive], html: false))],
      [:drawdown_request, t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(domestic_outgoing_wires_root[:drawdown_request], html: false))],
      [:standing_request, t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(domestic_outgoing_wires_root[:standing_request], html: false))]
    ]
    @domestic_outgoing_wires_table = fee_schedule_table_hash(domestic_outgoing_wires_rows)

    # Wire Transfer and STA - domestic incoming wires
    @domestic_incoming_wires_table = fee_schedule_table_hash([[:domestic_incoming_wires, t('resources.fee_schedules.amount_per_wire', amount: fhlb_formatted_currency(fees[:wire_transfer_and_sta][:domestic_incoming_wires], html: false))]])

    # Wire Transfer and STA - overdraft charges
    overdraft_charges_root = fees[:wire_transfer_and_sta][:overdraft_charges]
    overdraft_charges_rows = [
      [:interest_rate, t('resources.fee_schedules.interest_rate_overdraft', basis_points: overdraft_charges_root[:interest_rate])],
      [:processing_fee, t('resources.fee_schedules.amount_per_overdraft', amount: fhlb_formatted_currency(overdraft_charges_root[:processing_fee], html: false))]
    ]
    @overdraft_charges_table = fee_schedule_table_hash(overdraft_charges_rows)

    # Wire Transfer and STA - miscellaneous
    sta_miscellaneous_root = fees[:wire_transfer_and_sta][:miscellaneous]
    sta_miscellaneous_rows = [
      [:photocopies, t('resources.fee_schedules.amount_per_statement', amount: fhlb_formatted_currency(sta_miscellaneous_root[:photocopies], html: false))],
      [:special_account_research, t('resources.fee_schedules.amount_per_hour', amount: fhlb_formatted_currency(sta_miscellaneous_root[:special_account_research], html: false))]
    ]
    @sta_miscellaneous_table = fee_schedule_table_hash(sta_miscellaneous_rows)
  end

  # GET
  def membership_overview
  end

  # GET
  def membership_application
  end

  # GET
  def commercial_application
    @application_table_rows = application_table_rows(APPLICATION_FORM_IDS[:commercial])
  end

  # GET
  def community_development_application
    @application_table_rows = application_table_rows(APPLICATION_FORM_IDS[:community_development])
  end

  #GET
  def credit_union_application
    @application_table_rows = application_table_rows(APPLICATION_FORM_IDS[:credit_union])
  end

  #GET
  def insurance_company_application
    @application_table_rows = application_table_rows(APPLICATION_FORM_IDS[:insurance_company])
  end

  private

  def docusign_link(form)
    form = form.to_s
    docusign = DocusignService.new(request).get_url(form, current_user, current_member_id)
    raise StandardError, "There has been an error and ResourcesController##{form} has encountered nil. Check error logs." if docusign.nil?
    docusign[:link].to_s
  end

  def fee_schedule_table_hash(rows)
    raise ArgumentError.new('`rows` must not be nil') if rows.nil?
    table_data = {
      rows: []
    }
    rows.each do |row|
      table_data[:rows].push(
        {
          columns: [
            {value: t("resources.fee_schedules.#{row.first.to_s}")},
            {value: row[1], type: row[2]}
          ]
        }
      )
    end
    table_data
  end

  def form_description_from_id(form_id)
    description = case form_id
    when 2104, 2112, 2178
      t("resources.membership.forms.id_#{form_id.to_s}.description_html", link: link_to(ContactInformationHelper::MEMBERSHIP_EMAIL, membership_email))
    when 2136
      t("resources.membership.forms.id_#{form_id.to_s}.description_html", download_link: link_to_download_resource(t('resources.membership.forms.id_2135.title'), resources_download_path(file: :form_2135)))
    when 2349
      t("resources.membership.forms.id_#{form_id.to_s}.description_html", download_link: link_to_download_resource(t('resources.membership.forms.id_2127.title'), resources_download_path(file: :form_2127)))
    when 1973
      t("resources.membership.forms.id_1973.description_html", link: link_to(ContactInformationHelper::MEMBERSHIP_EMAIL, membership_email))
    else
      t("resources.membership.forms.id_#{form_id.to_s}.description")
    end
    description.html_safe
  end

  def add_link_to_row(row)
    form_id = row[:form_number]
    case form_id.to_i
    when *FORMS_WITHOUT_LINKS
      nil
    else
      row[:pdf_link] = resources_download_path(file: :"form_#{form_id}")
    end
    row
  end

  def application_table_rows(form_id_hash)
    rows_hash = {}
    form_id_hash.each do |row_type, form_ids|
      rows_hash[row_type] = form_ids.collect do |form_id|
        if @cms_enabled
          form = Cms::Form.new(current_member_id, request, FORM_ID_CMS_KEY_MAPPING[form_id], @cms)
          title = form.application_page_title
          description = resolve_relative_prismic_links(form.description)
        else
          title = t("resources.membership.forms.id_#{form_id.to_s}.title")
          description = form_description_from_id(form_id)
        end
        row = {
          title: title,
          description: description,
          form_number: form_id
        }
        add_link_to_row(row)
      end
    end
    rows_hash
  end

  def forms_page_title_from_cms(cms, cms_key)
    Cms::Form.new(current_member_id, request, cms_key, cms).form_page_title
  end

end
