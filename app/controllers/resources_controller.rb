class ResourcesController < ApplicationController
  include CustomFormattingHelper
  
  # GET
  def guides
  end

  # GET
  def forms
    @agreement_rows  = [
      {
        title: t('resources.forms.agreements.advances'),
        rows: [
          {
            title: t('resources.forms.agreements.commercial_banks'),
            form_number: 2117,
            pdf_link: resources_download_path(file: :form_2117)
          },
          {
            title: t('resources.forms.agreements.community'),
            form_number: 2349,
            pdf_link: resources_download_path(file: :form_2349)
          },
          {
            title: t('resources.forms.agreements.credit_unions'),
            form_number: 2127,
            pdf_link: resources_download_path(file: :form_2127)
          },
          {
            title: t('resources.forms.agreements.insurance'),
            form_number: 2177,
            pdf_link: resources_download_path(file: :form_2177)
          }
        ]
      },
      {
        title: t('resources.forms.agreements.letters_of_credit'),
        form_number: 1465,
        pdf_link: resources_download_path(file: :form_1465)
      },
      {
        title: t('resources.forms.agreements.safekeeping'),
        form_number: 1694,
        pdf_link: resources_download_path(file: :form_1694)
      },
      {
        title: t('resources.forms.agreements.settlement_transaction_account'),
        form_number: 2136,
        pdf_link: resources_download_path(file: :form_2136)
      }
    ]
    
    @signature_card_rows = [
      {
        title: t('resources.forms.authorizations.signature_cards.member_transactions'),
        form_number: 2065,
        pdf_link: resources_download_path(file: :form_2065)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.entire_authority'),
        form_number: 2066,
        pdf_link: resources_download_path(file: :form_2066)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.wire_transfer'),
        form_number: 2108,
        pdf_link: resources_download_path(file: :form_2108)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.advances'),
        form_number: 2067,
        pdf_link: resources_download_path(file: :form_2067)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.affordable_housing'),
        form_number: 2153,
        pdf_link: resources_download_path(file: :form_2153)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.collateral'),
        form_number: 2068,
        pdf_link: resources_download_path(file: :form_2068)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.interest_rate'),
        form_number: 2070,
        pdf_link: resources_download_path(file: :form_2070)
      },
      {
        title: t('resources.forms.authorizations.signature_cards.money_market'),
        form_number: 2071,
        pdf_link: resources_download_path(file: :form_2071)
      }
    ]

    @wire_transfer_rows = [
      {
        title: t('resources.forms.authorizations.wire_transfer.repetitive'),
        form_number: 1685,
        pdf_link: resources_download_path(file: :form_1685)
      }
    ]

    @capital_stock_rows = [
      {
        title: t('resources.forms.authorizations.capital_stock.repurchase'),
        form_number: 2239,
        pdf_link: resources_download_path(file: :form_2239)
      },
      {
        title: t('resources.forms.authorizations.capital_stock.redemption'),
        form_number: 2238,
        pdf_link: resources_download_path(file: :form_2238)
      }
    ]

    @website_access_rows = [
      {
        title: t('resources.forms.authorizations.website.access_manager'),
        form_number: 2160,
        pdf_link: resources_download_path(file: :form_2160)
      },
      {
        title: t('resources.forms.authorizations.website.securid'),
        form_number: 2228,
        pdf_link: resources_download_path(file: :form_2228)
      }
    ]

    @credit_rows = [
      {
        title: t('resources.forms.credit.application'),
        form_number: 2051,
        pdf_link: resources_download_path(file: :form_2051)
      },
      {
        title: t('resources.forms.credit.ace_application'),
        form_number: 2192,
        pdf_link: resources_download_path(file: :form_2192)
      },
      {
        title: t('resources.forms.credit.reimbursement'),
        form_number: 1465,
        pdf_link: resources_download_path(file: :form_1465)
      },
      {
        title: t('resources.forms.credit.statement_of_authority'),
        rows: [
          {
            title: t('resources.forms.credit.prepayment_symmetry'),
            form_number: 2215,
            pdf_link: resources_download_path(file: :form_2215)
          },
          {
            title: t('resources.forms.credit.putable_advances'),
            form_number: 2161,
            pdf_link: resources_download_path(file: :form_2161)
          }
        ]
      },
    ]

    @lien_real_estate_rows = [
      {
        title: t('resources.forms.collateral.lien_real_estate.pledging'),
        form_number: 2237,
        pdf_link: resources_download_path(file: :form_2237)
      },
      {
        title: t('resources.forms.collateral.lien_real_estate.lending_policy'),
        form_number: 2281,
        pdf_link: resources_download_path(file: :form_2281)
      },
      {
        title: t('resources.forms.collateral.lien_real_estate.questionnaire_html').html_safe,
        form_number: 2242,
        pdf_link: resources_download_path(file: :form_2242)
      },
      {
        title: t('resources.forms.collateral.lien_real_estate.certification'),
        form_number: 2241,
        pdf_link: resources_download_path(file: :form_2241)
      },
      {
        title: t('resources.forms.collateral.lien_real_estate.notification'),
        form_number: 2243,
        pdf_link: resources_download_path(file: :form_2243)
      }
    ]

    @lien_other_rows = [
      {
        title: t('resources.forms.collateral.lien_other.certification'),
        form_number: 2202,
        pdf_link: resources_download_path(file: :form_2202)
      },
      {
        title: t('resources.forms.collateral.lien_other.release'),
        form_number: 2200,
        pdf_link: resources_download_path(file: :form_2200)
      }
    ]

    @specific_identification_rows = [
      {
        title: t('resources.forms.collateral.specific_identification.transmission'),
        form_number: 2249,
        pdf_link: resources_download_path(file: :form_2249)
      },
      {
        title: t('resources.forms.collateral.specific_identification.transmittal'),
        form_number: 1547,
        pdf_link: resources_download_path(file: :form_1547)
      },
      {
        title: t('resources.forms.collateral.specific_identification.questionnaire'),
        form_number: 2204,
        pdf_link: resources_download_path(file: :form_2204)
      }
    ]

    @deposits_rows  = [
      {
        title: t('resources.forms.collateral.deposits.pledge'),
        form_number: 1722,
        pdf_link: resources_download_path(file: :form_1722)
      }
    ]

    @securities_rows = [
      {
        title: t('resources.forms.collateral.securities.pledge'),
        form_number: 449,
        pdf_link: resources_download_path(file: :form_449)
      },
      {
        title: t('resources.forms.collateral.securities.release'),
        form_number: 1227,
        pdf_link: resources_download_path(file: :form_1227)
      },
      {
        title: t('resources.forms.collateral.securities.deposit'),
        form_number: 2143,
        pdf_link: resources_download_path(file: :form_2143)
      },
      {
        title: t('resources.forms.collateral.securities.safekeeping_release'),
        form_number: 2194,
        pdf_link: resources_download_path(file: :form_2194)
      }
    ]

    @loan_document_rows = [
      {
        title: t('resources.forms.collateral.loan_document.assignment'),
        word_link: resources_download_path(file: :corporation_assignment)
      }
    ]

    @creditor_relationship_rows = [
      {
        title: t('resources.forms.collateral.creditor_relationship.amendment'),
        word_link: resources_download_path(file: :credit_union_amendment)
      },
      {
        title: t('resources.forms.collateral.creditor_relationship.agreement'),
        form_number: 2373,
        pdf_link: resources_download_path(file: :credit_union_agreement)
      }
    ]
  end

  # GET
  def download
    case params[:file]
    when 'creditguide'
      filename = 'creditguide.pdf'
    when 'collateralguide'
      filename = 'collateralguide.pdf'
    when 'collateralreviewguide'
      filename = 'mortgage-loan-collateral-field-review-process.pdf'
    when 'corporation_assignment'
      filename = 'Corporate_Assignment.doc'
    when 'credit_union_amendment'
      filename = 'corporate-credit-union-amendment.docx'
    when 'credit_union_agreement'
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
    when /\Aform_(\d{3,4})\z/
      filename = "fc#{$1}.pdf"
    else
      raise ActionController::MissingFile
    end

    send_file Rails.root.join('private', filename), filename: filename
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
      [:other_purposes, t('resources.fee_schedules.basis_point_per_annum', basis_point: annual_maintenance_charge_root[:other_purposes])]
    ]
    @annual_maintenance_charge_table = fee_schedule_table_hash(annual_maintenance_charge_rows)
    
    # LOC - issuance fee
    issuance_fee_root = fees[:letters_of_credit][:issuance_fee]
    issuance_fee_rows = [
      [:agency_deposits, issuance_fee_root[:agency_deposits], :currency_whole],
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
  
  private
  
  def fee_schedule_table_hash(rows)
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

end
