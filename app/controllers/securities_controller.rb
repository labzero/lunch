class SecuritiesController < ApplicationController
  include CustomFormattingHelper

  SECURITIES_TRANSACTION_CODES = {
    standard: 'standard',
    repo: 'repo'
  }.freeze

  SECURITIES_SETTLEMENT_TYPES = {
    free: 'free',
    payment: 'payment'
  }.freeze

  SECURITIES_DELIVERY_INSTRUCTIONS = {
    dtc: 'dtc',
    fed: 'fed',
    mutual_fund: 'mutual_fund',
    physical: 'physical'
  }.freeze

  before_action do
    set_active_nav(:securities)
    @html_class ||= 'white-background'
  end

  def manage
    @title = t('securities.manage.title')
    member_balances = MemberBalanceService.new(current_member_id, request)
    securities = member_balances.managed_securities
    raise StandardError, "There has been an error and SecuritiesController#manage has encountered nil. Check error logs." if securities.nil?

    rows = []
    securities.each do |security|
      cusip = security[:cusip]
      status = custody_account_type_to_status(security[:custody_account_type])
      rows << {
        filter_data: status,
        columns:[
          {value: security.to_json, type: :checkbox, name: "securities[]", disabled: cusip.blank?, data: {status: status}},
          {value: cusip || t('global.missing_value')},
          {value: security[:description] || t('global.missing_value')},
          {value: status},
          {value: security[:eligibility] || t('global.missing_value')},
          {value: security[:maturity_date], type: :date},
          {value: security[:authorized_by] || t('global.missing_value')},
          {value: security[:current_par], type: :number},
          {value: security[:borrowing_capacity], type: :number}
        ]
      }
    end

    @securities_table_data = {
      filter: {
        name: 'securities-status-filter',
        data: [
          {
            text: t('securities.manage.safekept'),
            value: 'Safekept'
          },
          {
            text: t('securities.manage.pledged'),
            value: 'Pledged'
          },
          {
            text: t('securities.manage.all'),
            value: 'all',
            class: 'active'
          }
        ]
      },
      column_headings: [{value: 'check_all', type: :checkbox, name: 'check_all'}, t('common_table_headings.cusip'), t('common_table_headings.description'), t('common_table_headings.status'), t('securities.manage.eligibility'), t('common_table_headings.maturity_date'), t('common_table_headings.authorized_by'), fhlb_add_unit_to_table_header(t('common_table_headings.current_par'), '$'), fhlb_add_unit_to_table_header(t('global.borrowing_capacity'), '$')],
      rows: rows
    }

  end

  def requests
    @title = t('securities.requests.title')
    service = SecuritiesRequestService.new(current_member_id, request)
    authorized_requests = service.authorized
    awaiting_authorization_requests = service.awaiting_authorization
    raise StandardError, "There has been an error and SecuritiesController#requests has encountered nil. Check error logs." if authorized_requests.nil? || awaiting_authorization_requests.nil?
    
    @awaiting_authorization_requests_table = {
      column_headings: [
        t('securities.requests.columns.request_id'),
        t('common_table_headings.description'),
        t('securities.requests.columns.submitted_by'),
        t('securities.requests.columns.submitted_date'),
        t('common_table_headings.settlement_date'),
        t('global.actions')
      ],
      rows: awaiting_authorization_requests.collect do |request|
        {
          columns: [
            {value: request[:request_id]},
            {value: form_type_to_description(request[:form_type])},
            {value: request[:submitted_by]},
            {value: request[:submitted_date], type: :date},
            {value: request[:settle_date], type: :date},
            {value: [[t('securities.requests.actions.authorize'), '#']], type: :actions}
          ]
        }
      end
    }

    @authorized_requests_table = {
      column_headings: [
        t('securities.requests.columns.request_id'),
        t('common_table_headings.description'),
        t('common_table_headings.authorized_by'),
        t('securities.requests.columns.authorization_date'),
        t('common_table_headings.settlement_date'),
        t('global.actions')
      ],
      rows: authorized_requests.collect do |request|
        {
          columns: [
            {value: request[:request_id]},
            {value: form_type_to_description(request[:form_type])},
            {value: request[:authorized_by]},
            {value: request[:authorized_date], type: :date},
            {value: request[:settle_date], type: :date},
            {value: [[t('global.view'), '#']], type: :actions}
          ]
        }
      end
    }
  end

  # POST
  def edit_release
    @title = t('securities.release.title')
    @transaction_code_dropdown = [
      [t('securities.release.transaction_code.standard'), SECURITIES_TRANSACTION_CODES[:standard]],
      [t('securities.release.transaction_code.repo'), SECURITIES_TRANSACTION_CODES[:repo]]
    ]
    @settlement_type_dropdown = [
      [t('securities.release.settlement_type.free'), SECURITIES_SETTLEMENT_TYPES[:free]],
      [t('securities.release.settlement_type.vs_payment'), SECURITIES_SETTLEMENT_TYPES[:payment]]
    ]
    @delivery_instructions_dropdown = [
      [t('securities.release.delivery_instructions.dtc'), SECURITIES_DELIVERY_INSTRUCTIONS[:dtc]],
      [t('securities.release.delivery_instructions.fed'), SECURITIES_DELIVERY_INSTRUCTIONS[:fed]],
      [t('securities.release.delivery_instructions.mutual_fund'), SECURITIES_DELIVERY_INSTRUCTIONS[:mutual_fund]],
      [t('securities.release.delivery_instructions.physical_securities'), SECURITIES_DELIVERY_INSTRUCTIONS[:physical]]
    ]

    @securities_table_data = {
      column_headings: [t('common_table_headings.cusip'), t('common_table_headings.description'), fhlb_add_unit_to_table_header(t('common_table_headings.original_par'), '$'), fhlb_add_unit_to_table_header(t('securities.release.settlement_amount'), '$')],
      rows: params[:securities].collect do |security|
        security = JSON.parse(security).with_indifferent_access
        {
          columns: [
            {value: security[:cusip] || t('global.missing_value')},
            {value: security[:description] || t('global.missing_value')},
            {value: security[:original_par], type: :number},
            {value: nil, type: :number}
          ]
        }
      end
    }
  end

  private

  def custody_account_type_to_status(custody_account_type)
    custody_account_type = custody_account_type.to_s.upcase if custody_account_type
    case custody_account_type
      when 'P'
        I18n.t('securities.manage.pledged')
      when 'U'
        I18n.t('securities.manage.safekept')
      else
        I18n.t('global.missing_value')
    end
  end

  def form_type_to_description(form_type)
    case form_type
    when 'pledge_intake'
      t('securities.requests.form_descriptions.pledge')
    when 'pledge_release', 'safekept_release'
      t('securities.requests.form_descriptions.release')
    when 'safekept_intake'
      t('securities.requests.form_descriptions.safekept')
    else
      t('global.missing_value')
    end
  end

end