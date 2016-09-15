class SecuritiesController < ApplicationController
  include CustomFormattingHelper
  include ContactInformationHelper
  include ActionView::Helpers::TextHelper

  before_action only: [:view_release, :authorize_request, :view_request] do
    authorize :security, :authorize?
  end

  before_action only: [:delete_request] do
    authorize :security, :delete?
  end

  before_action only: [ :edit_safekeep, :edit_pledge, :edit_release, :view_release ] do
    @accepted_upload_mimetypes = ACCEPTED_UPLOAD_MIMETYPES.join(', ')
  end

  ACCEPTED_UPLOAD_MIMETYPES = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'text/csv',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/octet-stream'
  ]

  TRANSACTION_DROPDOWN_MAPPING = {
    standard: {
      text: 'securities.release.transaction_code.standard',
      value: SecuritiesRequest::TRANSACTION_CODES[:standard]
    },
    repo: {
      text: 'securities.release.transaction_code.repo',
      value: SecuritiesRequest::TRANSACTION_CODES[:repo]
    }
  }.freeze

  SETTLEMENT_TYPE_DROPDOWN_MAPPING = {
    free: {
      text: 'securities.release.settlement_type.free',
      value: SecuritiesRequest::SETTLEMENT_TYPES[:free]
    },
    vs_payment: {
      text: 'securities.release.settlement_type.vs_payment',
      value: SecuritiesRequest::SETTLEMENT_TYPES[:vs_payment]
    }
  }.freeze

  DELIVERY_INSTRUCTIONS_DROPDOWN_MAPPING = {
    dtc: {
      text: 'securities.release.delivery_instructions.dtc',
      value: SecuritiesRequest::DELIVERY_TYPES[:dtc]
    },
    fed: {
      text: 'securities.release.delivery_instructions.fed',
      value: SecuritiesRequest::DELIVERY_TYPES[:fed]
    },
    mutual_fund: {
      text: 'securities.release.delivery_instructions.mutual_fund',
      value: SecuritiesRequest::DELIVERY_TYPES[:mutual_fund]
    },
    physical_securities: {
      text: 'securities.release.delivery_instructions.physical_securities',
      value: SecuritiesRequest::DELIVERY_TYPES[:physical_securities]
    }
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
        kind = request[:kind]
        request_id = request[:request_id]
        view_path = case kind
        when 'pledge_release', 'safekept_release'
          securities_release_view_path(request_id)
        when 'pledge_intake'
          securities_pledge_view_path(request_id)
        when 'safekept_intake'
          securities_safekeep_view_path(request_id)
        when 'safekept_transfer', 'pledge_transfer'
          securities_transfer_view_path(request_id)
        end
        action_cell_value = policy(:security).authorize? ? [[t('securities.requests.actions.authorize'), view_path ]] : [t('securities.requests.actions.authorize')]
        {
          columns: [
            {value: request_id},
            {value: kind_to_description(kind)},
            {value: request[:submitted_by]},
            {value: request[:submitted_date], type: :date},
            {value: request[:settle_date], type: :date},
            {value: action_cell_value, type: :actions}
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
        kind = request[:kind]
        {
          columns: [
            {value: request[:request_id]},
            {value: kind_to_description(kind)},
            {value: request[:authorized_by]},
            {value: request[:authorized_date], type: :date},
            {value: request[:settle_date], type: :date},
            {value: [[t('global.view'), '#']], type: :actions}
          ]
        }
      end
    }
  end

  def edit_safekeep
    populate_view_variables(:safekeep)
    @securities_request.safekept_account = MembersService.new(request).member(current_member_id)['unpledged_account_number']
    @securities_request.kind = :safekept_intake
  end

  def edit_pledge
    populate_view_variables(:pledge)
    @securities_request.pledged_account = MembersService.new(request).member(current_member_id)['pledged_account_number']
    @securities_request.kind = :pledge_intake
  end

  # POST
  def edit_release
    populate_view_variables(:release)
    raise ArgumentError.new('Securities cannot be nil') unless @securities_request.securities.present?
    @securities_request.kind = case @securities_request.securities.first.custody_account_type
    when 'U'
      :safekept_release
    when 'P'
      :pledge_release
    else
      raise ArgumentError, 'Unrecognized `custody_account_type` for passed security.'
    end
  end

  # POST
  def edit_transfer
    populate_view_variables(:transfer)
    @securities_request.safekept_account = MembersService.new(request).member(current_member_id)['unpledged_account_number']
    @securities_request.pledged_account = MembersService.new(request).member(current_member_id)['pledged_account_number']
    case @securities_request.securities.first.custody_account_type
    when 'U'
      @securities_request.kind = :pledge_transfer
      @title = t('securities.transfer.pledge.title')
    when 'P'
      @securities_request.kind = :safekept_transfer
      @title = t('securities.transfer.safekeep.title')
    else
      raise ArgumentError, 'Unrecognized `custody_account_type` for passed security.'
    end
  end

  # GET
  def view_request
    request_id = params[:request_id]
    type = params[:type].try(:to_sym)
    @securities_request = SecuritiesRequestService.new(current_member_id, request).submitted_request(request_id)
    raise ActionController::RoutingError.new("There has been an error and SecuritiesController#view_request has encountered nil. Check error logs.") if @securities_request.nil?
    raise ActionController::RoutingError.new("The type specified by the `/securities/view` route does not match the @securities_request.kind. \nType: `#{type}`\nKind: `#{@securities_request.kind}`") unless type_matches_kind(type, @securities_request.kind)
    populate_view_variables(type)
    case type
    when :release
      render :edit_release
    when :pledge
      render :edit_pledge
    when :safekeep
      render :edit_safekeep
    else
      raise ArgumentError, "Unknown request type: #{type}"
    end
  end

  def download_release
    securities = JSON.parse(params[:securities]).collect! { |security| Security.from_hash(security) }
    populate_securities_table_data_view_variable(:release, securities)
    render xlsx: 'securities', filename: "securities.xlsx", formats: [:xlsx], locals: { type: :release }
  end

  def download_transfer
    securities = JSON.parse(params[:securities]).collect! { |security| Security.from_hash(security) }
    populate_securities_table_data_view_variable(:transfer, securities)
    render xlsx: 'securities', filename: "securities.xlsx", formats: [:xlsx], locals: { type: :transfer }
  end

  def download_safekeep
    populate_securities_table_data_view_variable(:safekeep)
    render xlsx: 'securities', filename: "securities.xlsx", formats: [:xlsx], locals: { type: :safekeep }
  end

  def upload_securities
    uploaded_file = params[:file]
    content_type = uploaded_file.content_type
    type = params[:type].to_sym
    error = nil
    if ACCEPTED_UPLOAD_MIMETYPES.include?(content_type)
      securities = []
      begin
        spreadsheet = Roo::Spreadsheet.open(uploaded_file.path)
      rescue ArgumentError, IOError, Zip::ZipError => e
        error = I18n.t('securities.upload_errors.cannot_open')
      end
      unless error
        data_start_index = nil
        invalid_cusips = []
        spreadsheet.each do |row|
          if data_start_index
            cusip = row[data_start_index]
            security = if type == :release
              Security.from_hash({
                cusip: cusip,
                description: row[data_start_index + 1],
                original_par: (row[data_start_index + 2]),
                payment_amount: (row[data_start_index + 3])
              })
            elsif type == :transfer
              Security.from_hash({
                cusip: cusip,
                description: row[data_start_index + 1],
                original_par: (row[data_start_index + 2])
              })
            elsif type == :pledge || type == :safekeep
              Security.from_hash({
                cusip: cusip,
                original_par: (row[data_start_index + 1]),
                payment_amount: (row[data_start_index + 2]),
                custodian_name: (row[data_start_index + 3])
              })
            end
            if security.valid?
              securities << security
            elsif security.errors.keys.include?(:cusip)
              invalid_cusips << security.cusip
            else
              error = prioritized_security_error(security)
              break
            end
          else
            row.each_with_index do |cell, i|
              regex = /\Acusip\z/i
              data_start_index = i if regex.match(cell.to_s)
            end
          end
        end
        if data_start_index && error.blank?
          cusip_error_count = invalid_cusips.length
          invalid_cusips.select!(&:present?)
          if invalid_cusips.present? && cusip_error_count == invalid_cusips.length
            # Invalid cusip error
            error = I18n.t('securities.upload_errors.invalid_cusips', cusips: invalid_cusips.join(', '))
          elsif cusip_error_count > 0
            # Blank cusip error
            error = I18n.t('activemodel.errors.models.security.blank')
          elsif securities.empty?
            error = I18n.t('securities.upload_errors.no_rows')
          else
            populate_securities_table_data_view_variable(type, securities)
            html = render_to_string(:upload_table, layout: false, locals: { type: type })
          end
        elsif error.blank?
          # No header row found (i.e. data_start_index)
          error = I18n.t('securities.upload_errors.generic')
        end
      end
    else
      error = I18n.t('securities.upload_errors.unsupported_mime_type')
    end
    render json: {html: html, form_data: (securities.to_json if securities && securities.present?), error: (simple_format(error) if error)}, content_type: request.format
  end

  def download_pledge
    populate_securities_table_data_view_variable(:pledge)
    render xlsx: 'securities', filename: "securities.xlsx", formats: [:xlsx], locals: { type: :pledge }
  end

  # POST
  def submit_request
    type = params[:type].try(:to_sym)
    @securities_request = SecuritiesRequest.from_hash(params[:securities_request])
    raise ArgumentError, "Unknown request type: #{type}" unless [:release, :pledge, :safekeep, :transfer].include?(type)
    kind = @securities_request.kind
    raise ActionController::RoutingError.new("The type specified by the `/securities/submit` route does not match the @securities_request.kind. \nType: `#{type}`\nKind: `#{kind}`") unless type_matches_kind(type, kind)
    authorizer = policy(:security).authorize?
    if @securities_request.valid?
      response = SecuritiesRequestService.new(current_member_id, request).submit_request_for_authorization(@securities_request, current_user, type) do |error|
        error = JSON.parse(error.http_body)['error']
        error['code'] = :base if error['code'] == 'unknown'
        @securities_request.errors.add(error['code'].to_sym, error['type'].to_sym)
      end
      @securities_request.errors.add(:base, :submission) unless response || @securities_request.errors.present?
    end
    has_errors = @securities_request.errors.present?
    if authorizer
      @securid_status = securid_perform_check unless has_errors
      unless session_elevated?
        has_errors = true
      end
      unless has_errors
        if SecuritiesRequestService.new(current_member_id, request).authorize_request(@securities_request.request_id, current_user)
          InternalMailer.securities_request_authorized(@securities_request)
        else
          @securities_request.errors.add(:base, :authorization)
          has_errors = true
        end
      end
    end
    if has_errors
      @error_message = prioritized_securities_request_error(@securities_request)
      populate_view_variables(type)
      case type
      when :release
        render :edit_release
      when :transfer
        render :edit_transfer
      when :pledge
        render :edit_pledge
      when :safekeep
        render :edit_safekeep
      end
    elsif authorizer
      case type
      when :release
        @title = t('securities.authorize.release.title')
      when :transfer
        @title = t('securities.authorize.transfer.title')
      when :pledge
        @title = t('securities.authorize.pledge.title')
      when :safekeep
        @title = t('securities.authorize.safekeep.title')
      end
      render :authorize_request
    else
      url = case kind
      when :pledge_release
        securities_release_pledge_success_url
      when :safekept_release
        securities_release_safekeep_success_url
      when :pledge_transfer
        securities_transfer_pledge_success_url
      when :safekept_transfer
        securities_transfer_safekeep_success_url
      when :pledge_intake
        securities_pledge_success_url
      when :safekept_intake
        securities_safekeep_success_url
      end
      redirect_to url
    end
  end

  def submit_request_success
    case params[:kind].to_sym
    when :pledge_release
      @title = t('securities.success.titles.pledge_release')
      @email_subject = t('securities.success.email.subjects.pledge_release')
    when :safekept_release
      @title = t('securities.success.titles.safekept_release')
      @email_subject = t('securities.success.email.subjects.safekept_release')
    when :pledge_intake
      @title = t('securities.success.titles.pledge_intake')
      @email_subject = t('securities.success.email.subjects.pledge_intake')
    when :safekept_intake
      @title = t('securities.success.titles.safekept_intake')
      @email_subject = t('securities.success.email.subjects.safekept_intake')
    when :pledge_transfer, :safekept_transfer
      @title = t('securities.success.titles.transfer')
      @email_subject = t('securities.success.email.subjects.transfer')
    end
    @authorized_user_data = []
    users = MembersService.new(request).signers_and_users(current_member_id) || []
    users.sort_by! { |user| [user[:surname] || '', user[:given_name] || ''] }
    users.each do |user|
      user[:roles].each do |role|
        if role == User::Roles::SECURITIES_SIGNER
          @authorized_user_data.push(user)
          break
        end
      end
    end
  end

  # DELETE
  def delete_request
    request_id = params[:request_id]
    response = SecuritiesRequestService.new(current_member_id, request).delete_request(request_id)
    status = response ? 200 : 404
    render json: {url: securities_requests_url, error_message: I18n.t('securities.release.delete_request.error_message')}, status: status
  end

  private

  def kind_to_description(kind)
    case kind
    when 'pledge_intake'
      t('securities.requests.form_descriptions.pledge')
    when 'pledge_release', 'safekept_release'
      t('securities.requests.form_descriptions.release')
    when 'safekept_intake'
      t('securities.requests.form_descriptions.safekept')
    when 'safekept_transfer', 'pledge_transfer'
      t('securities.requests.form_descriptions.transfer')
    else
      t('global.missing_value')
    end
  end

  def populate_securities_table_data_view_variable(type, securities=[])
    column_headings = []
    rows = []
    securities ||= []
    case type
    when :release
      column_headings = [ I18n.t('common_table_headings.cusip'),
        I18n.t('common_table_headings.description'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$'),
        I18n.t('securities.release.settlement_amount', unit: fhlb_add_unit_to_table_header('', '$'), footnote_marker: fhlb_footnote_marker) ]
      rows = securities.collect do |security|
        { columns: [
          {value: security.cusip || t('global.missing_value')},
          {value: security.description || t('global.missing_value')},
          {value: security.original_par, type: :number},
          {value: security.payment_amount, type: :number}
        ] }
      end
      when :transfer
      column_headings = [ I18n.t('common_table_headings.cusip'),
        I18n.t('common_table_headings.description'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$') ]
      rows = securities.collect do |security|
        { columns: [
          {value: security.cusip || t('global.missing_value')},
          {value: security.description || t('global.missing_value')},
          {value: security.original_par, type: :number}
        ] }
      end
    when :pledge, :safekeep
      column_headings = [ I18n.t('common_table_headings.cusip'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$'),
        I18n.t('securities.release.settlement_amount', unit: fhlb_add_unit_to_table_header('', '$'), footnote_marker: fhlb_footnote_marker),
        I18n.t('securities.safekeep.custodian_name', footnote_marker: fhlb_footnote_marker(1)) ]
      rows = securities.collect do |security|
        { columns: [
          {value: security.cusip || t('global.missing_value')},
          {value: security.original_par, type: :number},
          {value: security.payment_amount, type: :number},
          {value: security.custodian_name || t('global.missing_value')}
        ] }
      end
    end
    @securities_table_data = {
      column_headings: column_headings,
      rows: rows
    }
  end

  def populate_view_variables(type)
    @pledge_type_dropdown = [
      [t('securities.release.pledge_type.sbc'), SecuritiesRequest::PLEDGE_TO_VALUES[:sbc]],
      [t('securities.release.pledge_type.standard'), SecuritiesRequest::PLEDGE_TO_VALUES[:standard]]
    ]

    case type
    when :release
      @title = t('securities.release.title')
      @confirm_delete_text = t('securities.delete_request.titles.release')
    when :pledge
      @title = t('securities.pledge.title')
      @confirm_delete_text = t('securities.delete_request.titles.pledge')
    when :safekeep
      @title = t('securities.safekeep.title')
      @confirm_delete_text = t('securities.delete_request.titles.safekeep')
    when :transfer
      @confirm_delete_text = t('securities.delete_request.titles.transfer')
    end

    @session_elevated = session_elevated?

    @securities_request ||= SecuritiesRequest.new
    @securities_request.securities = params[:securities] if params[:securities]
    @securities_request.trade_date ||= Time.zone.today
    @securities_request.settlement_date ||= Time.zone.today

    populate_transaction_code_dropdown_variables(@securities_request)
    populate_settlement_type_dropdown_variables(@securities_request)
    populate_delivery_instructions_dropdown_variables(@securities_request)
    populate_securities_table_data_view_variable(type, @securities_request.securities)

    @form_data = {
      url: securities_release_submit_path,
      submit_text: policy(:security).authorize? ? t('securities.release.authorize') : t('securities.release.submit_authorization')
    }
    @date_restrictions = date_restrictions
  end

  def translated_dropdown_mapping(dropdown_hash)
    translated_dropdown_hash = {}
    dropdown_hash.each do |dropdown_key, value_hash|
      translated_value_hash = value_hash.clone
      translated_value_hash[:text] = I18n.t(translated_value_hash[:text])
      translated_dropdown_hash[dropdown_key] = translated_value_hash
    end
    translated_dropdown_hash
  end

  def populate_transaction_code_dropdown_variables(securities_request)
    transaction_dropdown_mapping = translated_dropdown_mapping(TRANSACTION_DROPDOWN_MAPPING)
    @transaction_code_dropdown = transaction_dropdown_mapping.values.collect(&:values)
    transaction_code = securities_request.transaction_code.try(:to_sym) || transaction_dropdown_mapping.keys.first
    @transaction_code_defaults = transaction_dropdown_mapping[transaction_code]
  end

  def populate_settlement_type_dropdown_variables(securities_request)
    settlement_type_dropdown_mapping = translated_dropdown_mapping(SETTLEMENT_TYPE_DROPDOWN_MAPPING)
    @settlement_type_dropdown = settlement_type_dropdown_mapping.values.collect(&:values)
    settlement_type = securities_request.settlement_type.try(:to_sym) || settlement_type_dropdown_mapping.keys.first
    @settlement_type_defaults = settlement_type_dropdown_mapping[settlement_type]
  end

  def populate_delivery_instructions_dropdown_variables(securities_request)
    delivery_instructions_dropdown_mapping = translated_dropdown_mapping(DELIVERY_INSTRUCTIONS_DROPDOWN_MAPPING)
    @delivery_instructions_dropdown = delivery_instructions_dropdown_mapping.values.collect(&:values)
    delivery_type = securities_request.delivery_type.try(:to_sym) || delivery_instructions_dropdown_mapping.keys.first
    @delivery_instructions_defaults = delivery_instructions_dropdown_mapping[delivery_type]
  end

  def date_restrictions
    today = Time.zone.today
    max_date = today + SecuritiesRequest::MAX_DATE_RESTRICTION
    holidays =  CalendarService.new(request).holidays(today, max_date)
    weekends = []
    date_iterator = today.clone
    while date_iterator <= max_date do
      weekends << date_iterator.iso8601 if (date_iterator.sunday? || date_iterator.saturday?)
      date_iterator += 1.day
    end
    {
      min_date: today,
      max_date: max_date,
      invalid_dates: holidays + weekends
    }
  end

  def prioritized_securities_request_error(securities_request)
    securities_request_errors = securities_request.errors
    specific_error_keys = [:settlement_date, :securities, :base]
    if securities_request_errors.present?
      general_error_keys = (securities_request_errors.keys - specific_error_keys)
      if general_error_keys.present?
        error_key = general_error_keys.first
        securities_request_errors[error_key].first
      elsif securities_request_errors[:settlement_date].present?
        securities_request_errors[:settlement_date].first
      elsif securities_request_errors[:securities].present?
        securities_request_errors[:securities].first
      else
        I18n.t('securities.release.edit.generic_error', phone_number: securities_services_phone_number, email: securities_services_email_text)
      end
    end
  end

  def prioritized_security_error(security)
    security_errors = security.errors
    if security_errors.present?
      error_keys = security_errors.keys
      prioritized_error_keys = error_keys - Security::CURRENCY_ATTRIBUTES
      error_key = prioritized_error_keys.present? ? prioritized_error_keys.first : error_keys.first
      security_errors[error_key].first
    end
  end

  def type_matches_kind(type, kind)
    case type
      when :release
        [:pledge_release, :safekept_release].include?(kind)
      when :transfer
        [:pledge_transfer, :safekept_transfer].include?(kind)
      when :safekeep
        kind == :safekept_intake
      when :pledge
        kind == :pledge_intake
    end
  end

end