class ResourcesController < ApplicationController

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
    when /\Aform_(\d{3,4})\z/
      filename = "fc#{$1}.pdf"
    else
      raise ActionController::MissingFile
    end

    send_file Rails.root.join('private', filename), filename: filename
  end

end
