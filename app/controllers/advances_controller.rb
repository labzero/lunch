class AdvancesController < ApplicationController
  include ReportsHelper
  include StreamingHelper
  include CustomFormattingHelper

  before_action do
    set_active_nav(:advances)
  end

  before_action :set_html_class

  before_action only: [:select_rate, :fetch_rates, :preview, :perform] do
    authorize :advance, :show?
  end

  before_action :fetch_advance_request, only: [:select_rate, :fetch_rates, :perform, :preview]

  after_action :save_advance_request, only: [:select_rate, :fetch_rates, :perform, :preview]

  before_action only: [:select_rate, :fetch_rates] do
    @advance_terms = AdvanceRequest::ADVANCE_TERMS
    @advance_types = AdvanceRequest::ADVANCE_TYPES
  end

  rescue_from AASM::InvalidTransition, AASM::UnknownStateMachineError, AASM::UndefinedState, AASM::NoDirectAssignmentError do |exception|
    logger.info { 'Exception: ' + exception.to_s }
    logger.info { 'Advance Request State at Exception: ' + advance_request.to_json }
    render :error
  end

  ADVANCES_ALL = 'all'.freeze
  ADVANCES_OUTSTANDING = 'outstanding'.freeze

  def confirmation
    render nothing: true
    MemberBalanceService.new(current_member_id, request).advance_confirmation(params[:advance_number],params[:confirmation_number], &stream_attachment_processor(response))
  end

  def manage
    column_headings = [t('common_table_headings.trade_date'), t('common_table_headings.funding_date'), t('common_table_headings.maturity_date'), t('common_table_headings.advance_number'), t('common_table_headings.advance_type'), t('advances.rate'), t('common_table_headings.current_par') + ' ($)']
    column_headings << t('advances.confirmation.title') if feature_enabled?('advance-confirmation')
    outstanding_only = params[:maturity] == ADVANCES_OUTSTANDING || params[:maturity].nil?
    @advances_data_table = {
      column_headings: column_headings,
      rows: [],
      filter: {
        name: 'advances-filter',
        remote: 'maturity',
        data: [
          {
            text: t('advances.manage_advances.outstanding'),
            value: ADVANCES_OUTSTANDING,
            active: outstanding_only
          },
          {
            text: t('advances.manage_advances.all'),
            value: ADVANCES_ALL,
            active: !outstanding_only
          }
        ]
      }
    }
    if params[:job_id]
      job_status = JobStatus.find_by(id: params[:job_id], user_id: current_user.id, status: JobStatus.statuses[:completed] )
      raise ActiveRecord::RecordNotFound unless job_status
      json = job_status.result_as_string
      raise StandardError, "There has been an error and AdvancesController#manage_advances has encountered nil. Check error logs." if json.nil?
      active_advances_response = JSON.parse(json).collect! {|o| o.with_indifferent_access}
      job_status.destroy
      rows = active_advances_response.collect do |row|
        columns = []
        [:trade_date, :funding_date, :maturity_date, :advance_number, :advance_type, :interest_rate, :current_par, :advance_confirmation].each do |key|
          value = row[key]
          if key == :interest_rate
            columns << {type: :index, value: value}
          elsif key == :current_par
            columns << {type: :number, value: value}
          elsif key == :trade_date || key == :funding_date || (key == :maturity_date and value != 'Open')
            columns << {type: :date, value: value}
          elsif key == :advance_confirmation
            if feature_enabled?('advance-confirmation')
              cell_value = advance_confirmation_link_data(row[:trade_date], value)
              columns << {type: :link_list, value: cell_value}
            else
              next
            end
          elsif key == :status || key == :original_par
            next
          else
            columns << {value: value}
          end
        end
        {columns: columns}
      end

      @advances_data_table[:rows] = rows

      render layout: false if request.xhr?
    else
      job_method = outstanding_only ? 'active_advances' : 'advances'
      job_status = MemberBalanceServiceJob.perform_later(current_member_id, job_method, request.uuid).job_status
      job_status.update_attributes!(user_id: current_user.id)
      @job_status_url = job_status_url(job_status)
      @load_url = advances_manage_url(job_id: job_status.id, maturity: outstanding_only ? ADVANCES_OUTSTANDING : ADVANCES_ALL )
      @advances_data_table[:deferred] = true
    end
  end

  # GET
  def select_rate
    etransact_service = EtransactAdvancesService.new(request)
    @limited_pricing_message = MessageService.new.todays_quick_advance_message
    @etransact_status = etransact_service.etransact_status(current_member_id)
    advance_params = params[:advance_request]
    if advance_params
      advance_request.type = advance_params[:type] unless advance_params[:type].blank?
      advance_request.term = advance_params[:term] unless advance_params[:term].blank?
      advance_request.amount = advance_params[:amount] unless advance_params[:amount].blank?
    end
    @advance_request_id = advance_request.id
    @selected_amount = advance_request.amount
    @selected_type = advance_request.type
    @selected_term = advance_request.term
    @active_term_type = advance_request.term_type || :vrc
    advance_request.allow_grace_period = true if etransact_service.etransact_active?
    @profile = sanitize_profile_if_endpoints_disabled(MemberBalanceService.new(current_member_id, request).profile)
  end

  # GET
  def fetch_rates
    etransact_service = EtransactAdvancesService.new(request)
    @add_advances_active = etransact_service.etransact_active?
    @rate_data = advance_request.rates
    @selected_type = advance_request.type
    @selected_term = advance_request.term

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }

    render json: {html: render_to_string(layout: false), id: advance_request.id}
  end

  # POST
  def preview
    advance_params = params[:advance_request]
    if advance_params
      advance_request.type = advance_params[:type] if advance_params[:type]
      advance_request.term = advance_params[:term] if advance_params[:term]
      if advance_params[:amount]
        advance_request.amount = advance_params[:amount]
        advance_request.stock_choice = nil
      end
    end
    advance_request.stock_choice = params[:stock_choice] if params[:stock_choice]

    advance_request.validate_advance

    if advance_request.errors.present?
      limit_error = advance_request.errors.find {|e| e.type == :limits}
      preview_errors = advance_request.errors.select {|e| e.type == :preview }
      rate_error = advance_request.errors.find {|e| e.type == :rate}
      other_errors = advance_request.errors - [limit_error, rate_error, *preview_errors]

      if limit_error.present?
        error = limit_error
      elsif rate_error.present?
        error = rate_error
      else
        collateral_error = preview_errors.find {|e| e.code == :collateral }
        other_preview_error = preview_errors.find {|e| e.code != :capital_stock }
        if collateral_error
          error = collateral_error
        elsif other_preview_error
          error = other_preview_error
        elsif other_errors.present?
          error = other_errors.first
        else # capstock error
          populate_advance_capstock_view_parameters
          render :capstock_purchase
        end
      end
      populate_advance_error_view_parameters(error_message: error.try(:code), error_value: error.try(:value))
      render :error if error
    else
      populate_advance_preview_view_parameters
      advance_request.timestamp!
    end

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }
  end

  # POST
  def perform
    unless session_elevated?
      securid = SecurIDService.new(current_user.username)
      begin
        securid.authenticate(params[:securid_pin], params[:securid_token])
        session_elevate! if securid.authenticated?
        securid_status = securid.status
      rescue SecurIDService::InvalidPin => e
        securid_status = 'invalid_pin'
      rescue SecurIDService::InvalidToken => e
        securid_status = 'invalid_token'
      end
    else
      securid_status = :authenticated
    end
    advance_success = false
    if session_elevated?
      expired_rate = advance_request.expired?
      if expired_rate
        populate_advance_error_view_parameters(error_message: :rate_expired)
      else
        advance_request.execute
        if advance_request.executed?
          advance_success = true
          populate_advance_summary_view_parameters
        else
          populate_advance_error_view_parameters
        end
      end
    end

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }
    logger.info { '  Execute Results: ' + {securid: securid_status, advance_success: advance_success}.inspect }

    if securid_status != :authenticated
      populate_advance_preview_view_parameters(securid_status: securid_status)
      render :preview
    elsif advance_success != true
      render :error
    end
  end

  private

  def populate_advance_summary_view_parameters
    @advance_request_id = advance_request.id
    @authorized_amount = advance_request.authorized_amount
    @cumulative_stock_required = advance_request.cumulative_stock_required
    @current_trade_stock_required = advance_request.current_trade_stock_required
    @pre_trade_stock_required = advance_request.pre_trade_stock_required
    @net_stock_required = advance_request.net_stock_required
    @gross_amount = advance_request.gross_amount
    @gross_cumulative_stock_required = advance_request.gross_cumulative_stock_required
    @gross_current_trade_stock_required = advance_request.gross_current_trade_stock_required
    @gross_pre_trade_stock_required = advance_request.gross_pre_trade_stock_required
    @gross_net_stock_required = advance_request.gross_net_stock_required
    @advance_amount = advance_request.amount
    @advance_description = advance_request.term_description
    @advance_type_raw = advance_request.type
    @advance_program = advance_request.program_name
    @advance_type = advance_request.human_type
    @human_interest_day_count = advance_request.human_interest_day_count
    @human_payment_on = advance_request.human_payment_on
    @advance_term = advance_request.human_term
    @advance_raw_term = advance_request.term
    @trade_date = advance_request.trade_date
    @funding_date = advance_request.funding_date
    @maturity_date = advance_request.maturity_date
    @advance_rate = advance_request.rate
    @initiated_at = advance_request.initiated_at
    @advance_number = advance_request.confirmation_number
    @collateral_type = advance_request.collateral_type
    @old_rate = advance_request.old_rate
    @rate_changed = advance_request.rate_changed?
    @total_amount = advance_request.total_amount
    @stock = advance_request.sta_debit_amount
  end

  def populate_advance_error_view_parameters(error_message:nil, error_value:nil)
    populate_advance_summary_view_parameters
    @error_message = error_message
    @error_value = error_value
  end

  def populate_advance_capstock_view_parameters
    populate_advance_summary_view_parameters
    @net_amount = @advance_amount.to_f - @net_stock_required.to_f
  end

  def populate_advance_preview_view_parameters(securid_status:nil)
    populate_advance_summary_view_parameters
    @session_elevated = session_elevated?
    @current_member_name = current_member_name
    @securid_status = securid_status
  end

  def fetch_advance_request
    advance_request_params = request.params[:advance_request] || {}
    id = advance_request_params[:id]
    @advance_request = id ? AdvanceRequest.find(id, request) : advance_request
    authorize @advance_request, :modify?
    @advance_request
  end

  def save_advance_request
    @advance_request.save if @advance_request
  end

  def advance_request
    @advance_request ||= AdvanceRequest.new(current_member_id, signer_full_name, request)
    @advance_request.owners.add(current_user.id)
    @advance_request
  end

  def set_html_class
    @html_class = 'white-background'
  end

  def advance_confirmation_link_data(trade_date, advance_confirmations)
    today = Time.zone.today
    trade_date = trade_date.to_date
    case advance_confirmations.length
    when 0
      if trade_date == today
        [I18n.t('advances.confirmation.in_progress')]
      else
        [I18n.t('advances.confirmation.not_available')]
      end
    when 1
      advance = advance_confirmations.first
      [[I18n.t('global.download'), advances_confirmation_path(advance_number: advance[:advance_number], confirmation_number: advance[:confirmation_number])]]
    else
      advance_confirmations.collect do |advance|
        date = fhlb_date_standard_numeric(advance[:confirmation_date])
        path = advances_confirmation_path(advance_number: advance[:advance_number], confirmation_number: advance[:confirmation_number])
        [I18n.t('advances.confirmation.download_date', date: date), path]
      end
    end
  end
end