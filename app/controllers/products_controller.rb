class ProductsController < ApplicationController

  before_action do
    @html_class ||= 'white-background'
    set_active_nav(:products)
  end

  # GET
  def index
  end

  # GET
  def arc_embedded
    @last_modified = Date.new(2012,12,1)
  end

  # GET
  def amortizing
    @last_modified = Date.new(2003, 12, 1)
  end

  # GET
  def auction_indexed
    @last_modified = Date.new(2011, 4, 1)
  end

  # GET
  def authorizations
    @last_modified = Date.new(2015, 10, 1)
  end

  # GET
  def choice_libor
    @last_modified = Date.new(2015, 4, 1)
  end

  # GET
  def callable
    @last_modified = Date.new(2008, 7, 1)
  end

  # GET
  def frc
    @last_modified = Date.new(2011, 4, 1)
  end

  # GET
  def frc_embedded
    @last_modified = Date.new(2009, 12, 1)
  end

  # GET
  def arc
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def knockout
    @last_modified = Date.new(2012, 12, 1)
  end

  # GET
  def ocn
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def putable
    @last_modified = Date.new(2012, 12, 1)
  end

  # GET
  def vrc
    @last_modified = Date.new(2011, 2, 1)
  end

  # GET
  def sbc
    @last_modified = Date.new(2016, 7, 1)
  end

  # GET
  def mpf
    @last_modified = Date.new(2015, 8, 1)
  end

  # GET
  def pfi
    @all_applicants_rows = [
      {
        title: t('products.advances.pfi.all_applicants.mpf_participating'),
        pdf_link: resources_download_path(file: :pfi_agreement_resolution)
      },
      {
        title: t('products.advances.pfi.all_applicants.delegation_of_authority'),
        pdf_link: resources_download_path(file: :delegation_of_authority)
      },
      {
        title: t('products.advances.pfi.all_applicants.delegation_of_authority_requests'),
        pdf_link: resources_download_path(file: :delegation_of_authority_requests)
      },
      {
        title: t('products.advances.pfi.all_applicants.delegation_of_authority_definitions'),
        pdf_link: resources_download_path(file: :delegation_of_authority_definitions)
      },
      {
        title: t('products.advances.pfi.all_applicants.participating_financial_institution_agreement'),
        pdf_link: resources_download_path(file: :pfi_agreement)
      },
      {
        title: t('products.advances.pfi.all_applicants.participating_financial_institution_application'),
        pdf_link: resources_download_path(file: :pfi_application)
      },
      {
        title: t('products.advances.pfi.all_applicants.mortgage_operations_questionnaire'),
        pdf_link: resources_download_path(file: :mortgage_operations_questionnaire)
      },
      {
        title: t('products.advances.pfi.all_applicants.mortgage_operations_questionnaire_addendum'),
        pdf_link: resources_download_path(file: :mortgage_operations_questionnaire_addendum)
      },
      {
        title: t('products.advances.pfi.all_applicants.mpf_fidelity'),
        pdf_link: resources_download_path(file: :mpf_fidelity)
      },
      {
        title: t('products.advances.pfi.all_applicants.anti_predatory'),
        pdf_link: resources_download_path(file: :anti_predatory)
      },
      {
        title: t('products.advances.pfi.all_applicants.in_house'),
        pdf_link: resources_download_path(file: :in_house)
      }
    ]

    @mpf_original_rows = [
      {
        title: t('products.advances.pfi.product_specific.collateral_file'),
        pdf_link: resources_download_path(file: :collateral_file)
      },
      {
        title: t('products.advances.pfi.product_specific.post_closing'),
        pdf_link: resources_download_path(file: :post_closing)
      },
      {
        title: t('products.advances.pfi.product_specific.servicer'),
        pdf_link: resources_download_path(file: :servicer)
      },
      {
        title_only: t('products.advances.pfi.product_specific.servicing_retained_only'),
        rows: [
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account_remittance'),
            pdf_link: resources_download_path(file: :servicer_account_remittance)
          },
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account_actual'),
            pdf_link: resources_download_path(file: :servicer_account_actual)
          },
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account'),
            pdf_link: resources_download_path(file: :servicer_account)
          }
        ]
      }
    ]

    @mpf_government_rows = [
      {
        title_only: t('products.advances.pfi.product_specific.servicing_retained_only'),
        rows: [
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account_remittance'),
            pdf_link: resources_download_path(file: :servicer_account_remittance)
          },
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account_actual'),
            pdf_link: resources_download_path(file: :servicer_account_actual)
          },
          {
            title: t('products.advances.pfi.product_specific.agreement_servicer_account'),
            pdf_link: resources_download_path(file: :servicer_account)
          }
        ]
      }
    ]

    @mpf_xtra_rows = [
      {
        title: t('products.advances.pfi.product_specific.mpf_extra_agreement'),
        pdf_link: resources_download_path(file: :xtra_agreement)
      },
      {
        title: t('products.advances.pfi.product_specific.collateral_file'),
        pdf_link: resources_download_path(file: :collateral_file)
      },
      {
        title: t('products.advances.pfi.product_specific.post_closing'),
        pdf_link: resources_download_path(file: :post_closing)
      },
      {
        title: t('products.advances.pfi.product_specific.servicer'),
        pdf_link: resources_download_path(file: :servicer)
      },
      {
        title_only: t('products.advances.pfi.product_specific.servicing_retained_only'),
        rows: [
          {
            title: t('products.advances.pfi.product_specific.mpf_xtra_addendum_mpf'),
            pdf_link: resources_download_path(file: :xtra_addendum_mpf)
          },
          {
            title: t('products.advances.pfi.product_specific.mpf_xtra_addendum_servcer_account'),
            pdf_link: resources_download_path(file: :xtra_addendum_servcer_account)
          },
          {
            title: t('products.advances.pfi.product_specific.mpf_extra'),
            pdf_link: resources_download_path(file: :xtra)
          }
        ]
      },
      {
        title_only: t('products.advances.pfi.product_specific.servicing_released_only'),
        rows: [
          {
            title: t('products.advances.pfi.product_specific.mpf_xtra_addendum_mpf_released'),
            pdf_link: resources_download_path(file: :xtra_addendum_mpf_released)
          }
        ]
      }
    ]

    @mpf_direct_rows = [
      {
        title: t('products.advances.pfi.product_specific.mpf_direct_agreement'),
        pdf_link: resources_download_path(file: :direct_agreement)
      },
      {
        title: t('products.advances.pfi.product_specific.mpf_direct_questionnaire'),
        pdf_link: resources_download_path(file: :direct_questionnaire)
      }
    ]

    @last_modified = Date.new(2015, 8, 1)
  end

  # GET
  def swaps
    @last_modified = Date.new(2011, 4, 1)
  end

end
