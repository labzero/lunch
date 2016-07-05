class SecuritiesController < ApplicationController
  include CustomFormattingHelper

  ACCEPTED_UPLOAD_MIMETYPES = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'text/csv',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/octet-stream'
  ]

  before_action do
    set_active_nav(:securities)
    @html_class ||= 'white-background'
  end

  def manage
    @title = t('securities.manage.title')
    member_balances = MemberBalanceService.new(current_member_id, request)
    securities = member_balances.managed_securities
    raise StandardError, "There has been an error and SecuritiesController#manage has encountered nil. Check error logs." if securities.nil?

    securities.collect! { |security| Security.from_hash(security) }
    rows = []
    securities.each do |security|
      cusip = security.cusip
      status = Security.human_custody_account_type_to_status(security.custody_account_type)
      rows << {
        filter_data: status,
        columns:[
          {value: security.to_json, type: :checkbox, name: "securities[]", disabled: cusip.blank?, data: {status: status}},
          {value: cusip || t('global.missing_value')},
          {value: security.description || t('global.missing_value')},
          {value: status},
          {value: security.eligibility || t('global.missing_value')},
          {value: security.maturity_date, type: :date},
          {value: security.authorized_by || t('global.missing_value')},
          {value: security.current_par, type: :number},
          {value: security.borrowing_capacity, type: :number}
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
            active: true
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
    populate_edit_release_view_variables
  end

  def download_release
    securities = JSON.parse(params[:securities]).collect! { |security| Security.from_hash(security) }
    populate_securities_table_data_view_variable(securities)
    render xlsx: 'release', filename: "securities.xlsx", formats: [:xlsx]
  end

  def upload_release
    uploaded_file = params[:file]
    content_type = uploaded_file.content_type
    if ACCEPTED_UPLOAD_MIMETYPES.include?(content_type)
      securities = []
      spreadsheet = Roo::Spreadsheet.open(uploaded_file.path)
      data_start_index = nil
      spreadsheet.each do |row|
        if data_start_index
          securities << Security.from_hash({
            cusip: row[data_start_index],
            description: row[data_start_index + 1],
            original_par: (row[data_start_index + 2].to_i if row[data_start_index + 2]),
            payment_amount: (row[data_start_index + 3].to_i if row[data_start_index + 3])
          })
        else
          row.each_with_index do |cell, i|
            regex = /\Acusip\z/i
            data_start_index = i if regex.match(cell.to_s)
          end
        end
      end
      if data_start_index
        populate_securities_table_data_view_variable(securities)
        html = render_to_string(layout: false)
        status = 200
      else
        error = 'No header row found'
        status = 400
      end
    else
      error = "Uploaded file has unsupported MIME type: #{content_type}"
      status = 415
    end
    render json: {html: html, form_data: (securities.to_json if securities), error: error}, status: status, content_type: request.format
  end

  # POST
  def submit_release
    @securities_release_request = SecuritiesReleaseRequest.from_hash(params[:securities_release_request])
    errors = nil
    if @securities_release_request.valid?
      response = SecuritiesRequestService.new(current_member_id, request).submit_release_for_authorization(@securities_release_request, current_user) do |error|
        errors = { mapi_endpoint: [error.http_body] }
      end
      errors ||= { mapi_endpoint: ['SecuritiesRequestService#submit_release_for_authorization has returned nil'] } unless response
    else
      errors = @securities_release_request.errors.messages
    end
    if errors
      populate_edit_release_view_variables(errors) # TODO - handle errors in the 'edit_release' view as part of MEM-1593
      render :edit_release
    else
      redirect_to securities_success_url
    end
  end

  def submit_release_success
    @title = t('securities.success.title')
    @authorized_user_data = []
    users = MembersService.new(request).signers_and_users(current_member_id) || []
    users.sort_by! { |user| [user[:surname] || '', user[:given_name] || ''] }
    users.each do |user|
      user[:roles].each do |role|
        if role == User::Roles::SECURITIES_SIGNER
          @authorized_user_data.push(user)
          break;
        end
      end
    end
  end

  private

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

  def populate_securities_table_data_view_variable(securities)
    column_headings = [
      I18n.t('common_table_headings.cusip'),
      I18n.t('common_table_headings.description'),
      fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$'),
      I18n.t('securities.release.settlement_amount', unit: fhlb_add_unit_to_table_header('', '$'), footnote_marker: fhlb_footnote_marker)
    ]
    securities ||= []
    rows = securities.collect do |security|
      {
        columns: [
          {value: security.cusip || t('global.missing_value')},
          {value: security.description || t('global.missing_value')},
          {value: security.original_par, type: :number},
          {value: security.payment_amount, type: :number}
        ]
      }
    end
    @securities_table_data = {
      column_headings: column_headings,
      rows: rows
    }
  end

  def populate_edit_release_view_variables(errors=nil)
    @errors = errors if errors
    @title = t('securities.release.title')
    @transaction_code_dropdown = [
      [t('securities.release.transaction_code.standard'), SecuritiesReleaseRequest::TRANSACTION_CODES[:standard]],
      [t('securities.release.transaction_code.repo'), SecuritiesReleaseRequest::TRANSACTION_CODES[:repo]]
    ]
    @settlement_type_dropdown = [
      [t('securities.release.settlement_type.free'), SecuritiesReleaseRequest::SETTLEMENT_TYPES[:free]],
      [t('securities.release.settlement_type.vs_payment'), SecuritiesReleaseRequest::SETTLEMENT_TYPES[:payment]]
    ]
    @delivery_instructions_dropdown = [
      [t('securities.release.delivery_instructions.dtc'), SecuritiesReleaseRequest::DELIVERY_TYPES[:dtc]],
      [t('securities.release.delivery_instructions.fed'), SecuritiesReleaseRequest::DELIVERY_TYPES[:fed]],
      [t('securities.release.delivery_instructions.mutual_fund'), SecuritiesReleaseRequest::DELIVERY_TYPES[:mutual_fund]],
      [t('securities.release.delivery_instructions.physical_securities'), SecuritiesReleaseRequest::DELIVERY_TYPES[:physical_securities]]
    ]

    @securities_release_request ||= SecuritiesReleaseRequest.new
    @securities_release_request.securities = params[:securities] if params[:securities]
    @securities_release_request.trade_date ||= Time.zone.today
    @securities_release_request.settlement_date ||= Time.zone.today
    populate_securities_table_data_view_variable(@securities_release_request.securities)
  end

end