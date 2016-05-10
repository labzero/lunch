class DashboardController < ApplicationController
  include CustomFormattingHelper
  include DashboardHelper
  include AssetHelper
  include ReportsHelper

  before_action only: [:quick_advance_rates, :quick_advance_preview, :quick_advance_perform, :quick_advance_started] do
    authorize :advances, :show?
  end

  before_action only: [:quick_advance_perform, :quick_advance_preview, :quick_advance_started] do
    advance_request_from_session(params[:id])
  end

  after_action only: [:quick_advance_rates, :quick_advance_perform, :quick_advance_preview, :quick_advance_started] do
    advance_request_to_session
  end

  before_action only: [:quick_advance_rates, :index] do
    @advance_terms = AdvanceRequest::ADVANCE_TERMS
    @advance_types = AdvanceRequest::ADVANCE_TYPES
  end

  prepend_around_action :skip_timeout_reset, only: [:current_overnight_vrc]

  rescue_from AASM::InvalidTransition, AASM::UnknownStateMachineError, AASM::UndefinedState, AASM::NoDirectAssignmentError do |exception|
    logger.info { 'Advance Request State at Exception: ' + advance_request.to_json }
    raise exception
  end

  # {action_name: [job_klass, path_helper_as_string]}
  DEFERRED_JOBS = {
    recent_activity: [MemberBalanceTodaysCreditActivityJob, "dashboard_recent_activity_url"],
    account_overview: [MemberBalanceProfileJob, "dashboard_account_overview_url"]
  }.freeze

  QUICK_REPORT_MAPPING = {
    account_summary: I18n.t('reports.account.account_summary.title'),
    advances_detail: I18n.t('reports.credit.advances_detail.title'),
    borrowing_capacity: I18n.t('reports.collateral.borrowing_capacity.title'),
    settlement_transaction_account: I18n.t('reports.account.settlement_transaction_account.title')
  }.with_indifferent_access.freeze

  def index
    rate_service = RatesService.new(request)
    etransact_service = EtransactAdvancesService.new(request)
    member_balances = MemberBalanceService.new(current_member_id, request)
    members_service = MembersService.new(request)
    populate_deferred_jobs_view_parameters(DEFERRED_JOBS)
    profile = sanitize_profile_if_endpoints_disabled(member_balances.profile)

    @market_overview = [{
      name: 'Test',
      data: members_service.report_disabled?(current_member_id, [MembersService::IRDB_RATES_DATA]) ? nil : rate_service.overnight_vrc
    }]

    @financing_availability_gauge = if profile[:total_financing_available]
      calculate_gauge_percentages(
        {
          total: profile[:total_financing_available],
          used: profile[:used_financing_availability],
          unused: profile[:collateral_borrowing_capacity][:remaining],
          uncollateralized: profile[:uncollateralized_financing_availability]
        }, :total)
    else
      calculate_gauge_percentages({total: 0})
    end

    current_rate = rate_service.current_overnight_vrc
    @current_overnight_vrc = if current_rate
      current_rate[:rate]
    else
      nil
    end

    @limited_pricing_message = MessageService.new.todays_quick_advance_message
    if feature_enabled?('add-advance')
      @etransact_status = etransact_service.etransact_status(current_member_id)
    else
      @quick_advance_enabled = members_service.quick_advance_enabled_for_member?(current_member_id)
      etransact_status = etransact_service.status
      quick_advance_open = etransact_service.etransact_active?(etransact_status)
      quick_advance_terms = etransact_service.has_terms?(etransact_status)
      @quick_advance_status = (quick_advance_open ? (quick_advance_terms ? :open : :no_terms) : :closed)
      # TODO replace this with the timestamp from the cached quick advance rates timestamp
      date = DateTime.now - 2.hours
      @quick_advance_last_updated = date.strftime("%d %^b %Y, %l:%M %p")
    end
    @contacts = Rails.cache.fetch(CacheConfiguration.key(:member_contacts, current_member_id),
                                  expires_in: CacheConfiguration.expiry(:member_contacts)) do
      members_service.member_contacts(current_member_id) || {}
    end
    default_image_path = 'placeholder-usericon.svg'
    if @contacts[:rm] && @contacts[:rm][:username]
      rm_image_path = "#{@contacts[:rm][:username].downcase}.jpg"
      @contacts[:rm][:image_url] = find_asset(rm_image_path) ? rm_image_path : default_image_path
    end
    if @contacts[:cam] && @contacts[:cam][:username]
      cam_image_path = "#{@contacts[:cam][:username].downcase}.jpg"
      @contacts[:cam][:image_url] = find_asset(cam_image_path) ? cam_image_path : default_image_path
    end
    if feature_enabled?('quick-reports')
      current_report_set = QuickReportSet.for_member(current_member_id).latest_with_reports
      @quick_reports = {}.with_indifferent_access
      if current_report_set.present?
        @quick_reports_period = (current_report_set.period + '-01').to_date # covert period to date
        current_report_set.member.quick_report_list.each do |report_name|
          @quick_reports[report_name] = {
            title: QUICK_REPORT_MAPPING[report_name]
          }
        end
        current_report_set.reports_named(@quick_reports.keys).completed.each do |quick_report|
          @quick_reports[quick_report.report_name][:url] = reports_quick_download_path(quick_report)
        end
      end
    end
  end

  def quick_advance_rates
    etransact_service = EtransactAdvancesService.new(request)
    @quick_advances_active = etransact_service.etransact_active?
    advance_request.allow_grace_period = true if @quick_advances_active
    @rate_data = advance_request.rates

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }

    render json: {html: render_to_string(layout: false), id: advance_request.id}
  end

  def quick_advance_preview
    @current_member_name = current_member_name
    @preview = true

    advance_request.type = params[:advance_type] if params[:advance_type]
    advance_request.term = params[:advance_term] if params[:advance_term]
    if params[:amount]
      advance_request.amount = params[:amount]
      advance_request.stock_choice = nil
    end
    advance_request.stock_choice = params[:stock_choice] if params[:stock_choice]

    advance_request.validate_advance
    populate_advance_request_view_parameters

    if advance_request.errors.present?
      limit_error = advance_request.errors.find {|e| e.type == :limits}
      preview_errors = advance_request.errors.select {|e| e.type == :preview }
      rate_error = advance_request.errors.find {|e| e.type == :rate}
      other_errors = advance_request.errors - [limit_error, rate_error, *preview_errors]

      if limit_error.present?
        preview_success = false
        preview_error = true
        @error_message = limit_error.code
        @error_value = limit_error.value
      elsif rate_error.present?
        preview_success = false
        preview_error = true
        @error_message = rate_error.code
      else
        collateral_error = preview_errors.find {|e| e.code == :collateral }
        other_preview_error = preview_errors.find {|e| e.code != :capital_stock }
        if collateral_error
          preview_success = false
          preview_error = true
          @error_message = collateral_error.code
          @error_value = collateral_error.value
        elsif other_preview_error
          preview_success = false
          preview_error = true
          @error_message = other_preview_error.code
          @error_value = other_preview_error.value
        elsif other_errors.present?
          preview_success = false
          preview_error = true
          @error_message = :unknown
        else # capital stock error
          preview_success = false
          preview_error = false
          @original_amount = advance_request.amount
          @net_amount = @original_amount - @net_stock_required
          response_html = render_to_string :quick_advance_capstock, layout: false
        end
      end
    else
      preview_success = true
      preview_error = false
    end

    if preview_error
      response_html = render_to_string :quick_advance_error, layout: false
    elsif !response_html
      @original_amount = @advance_amount.to_f
      @stock = advance_request.sta_debit_amount
      @session_elevated = session_elevated?
      advance_request.timestamp!
      response_html = render_to_string layout: false
    end

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }
    logger.info { '  Preview Results: ' + {preview_success: preview_success, preview_error: preview_error}.inspect }

    render json: {preview_success: preview_success, preview_error: preview_error, html: response_html}
  end

  def quick_advance_perform
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
    response_html = false
    if session_elevated?
      expired_rate = advance_request.expired?
      if expired_rate
        advance_success = false
        populate_advance_request_view_parameters
        @error_message = :rate_expired
        response_html = render_to_string :quick_advance_error, layout: false
      else
        advance_request.execute
        if advance_request.executed?
          advance_success = true
          populate_advance_request_view_parameters
          @stock = advance_request.sta_debit_amount
          response_html = render_to_string layout: false
        end
      end
    end

    logger.info { '  Advance Request State: ' + advance_request.inspect }
    logger.info { '  Advance Request Errors: ' + advance_request.errors.inspect }
    logger.info { '  Execute Results: ' + {securid: securid_status, advance_success: advance_success}.inspect }

    render json: {securid: securid_status, advance_success: advance_success, html: response_html}
  end

  def current_overnight_vrc
    etransact_service = EtransactAdvancesService.new(request)
    response = RatesService.new(request).current_overnight_vrc || {}
    response[:etransact_active] = etransact_service.etransact_active?
    response[:rate] = fhlb_formatted_number(response[:rate], precision: 2, html: false) if response[:rate]
    render json: response
  end

  def recent_activity
    activities = deferred_job_data || []
    activities = activities.collect! {|o| o.with_indifferent_access}
    recent_activity_data = process_recent_activities(activities)
    render partial: 'dashboard/dashboard_recent_activity', locals: {table_data: recent_activity_data}, layout: false
  end

  def account_overview
    today = Time.zone.now.to_date
    member_balances = MemberBalanceService.new(current_member_id, request)
    members_service = MembersService.new(request)

    # Borrowing Capacity Gauge
    borrowing_capacity = member_balances.borrowing_capacity_summary(today)
    @borrowing_capacity_gauge = calculate_borrowing_capacity_gauge(borrowing_capacity) unless members_service.report_disabled?(current_member_id, [MembersService::COLLATERAL_REPORT_DATA])

    profile = deferred_job_data || {}
    profile = sanitize_profile_if_endpoints_disabled(profile.with_indifferent_access)

    # Account Overview Sub-Tables - format: [title, value, footnote(optional), precision(optional)]
    # STA Balance Sub-Table
    sta_balance = [
      [[t('dashboard.your_account.table.balance'), reports_settlement_transaction_account_path], profile[:sta_balance], t('dashboard.your_account.table.balance_footnote')],
    ]

    # Credit Outstanding Sub-Table
    credit_outstanding = [
      [t('dashboard.your_account.table.credit_outstanding'), (profile[:credit_outstanding] || {})[:total]]
    ]

    # Remaining Borrowing Capacity Sub-Table
    total_standard_bc = borrowing_capacity[:net_plus_securities_capacity].to_i
    total_agency_bc = borrowing_capacity[:sbc][:collateral][:agency][:total_borrowing_capacity].to_i
    total_aaa_bc = borrowing_capacity[:sbc][:collateral][:aaa][:total_borrowing_capacity].to_i
    total_aa_bc = borrowing_capacity[:sbc][:collateral][:aa][:total_borrowing_capacity].to_i
    remaining_standard_bc = borrowing_capacity[:standard_excess_capacity].to_i
    remaining_agency_bc = borrowing_capacity[:sbc][:collateral][:agency][:remaining_borrowing_capacity].to_i
    remaining_aaa_bc = borrowing_capacity[:sbc][:collateral][:aaa][:remaining_borrowing_capacity].to_i
    remaining_aa_bc = borrowing_capacity[:sbc][:collateral][:aa][:remaining_borrowing_capacity].to_i

    remaining_borrowing_capacity = unless borrowing_capacity[:total_borrowing_capacity].to_i == 0
      bc_array = [{title: t('dashboard.your_account.table.remaining_borrowing_capacity')}]
      bc_array << [t('dashboard.your_account.table.remaining.standard'), remaining_standard_bc] unless total_standard_bc == 0
      bc_array << [t('dashboard.your_account.table.remaining.agency'), remaining_agency_bc] unless total_agency_bc == 0
      bc_array << [t('dashboard.your_account.table.remaining.aaa'), remaining_aaa_bc] unless total_aaa_bc == 0
      bc_array << [t('dashboard.your_account.table.remaining.aa'), remaining_aa_bc] unless total_aa_bc == 0
      bc_array
    end

    # Remaining Financing Availability and Stock Leverage Sub-Table
    leverage_title = if feature_enabled?('report-capital-stock-position-and-leverage')
      [t('dashboard.your_account.table.remaining.leverage'), reports_capital_stock_and_leverage_path]
    else
      t('dashboard.your_account.table.remaining.leverage')
    end
    other_remaining = [
      {title: t('dashboard.your_account.table.remaining.title')},
      [t('dashboard.your_account.table.remaining.available'), profile[:remaining_financing_available]],
      [leverage_title, (profile[:capital_stock] || {})[:remaining_leverage]]
    ]

    @account_overview_table_data = {credit_outstanding: credit_outstanding, sta_balance: sta_balance, remaining_borrowing_capacity: remaining_borrowing_capacity, other_remaining: other_remaining}
    render layout: false
  end

  private

  def populate_advance_request_view_parameters
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
  end

  def advance_request_from_session(id)
    @advance_request = id ? AdvanceRequest.find(id, request) : advance_request
    authorize @advance_request, :modify?
    @advance_request
  end

  def advance_request_to_session
    @advance_request.save if @advance_request
  end

  def advance_request
    @advance_request ||= AdvanceRequest.new(current_member_id, signer_full_name, request)
    @advance_request.owners.add(current_user.id)
    @advance_request
  end

  def signer_full_name
    session['signer_full_name'] ||= EtransactAdvancesService.new(request).signer_full_name(current_user.username)
  end

  def calculate_gauge_percentages(gauge_hash, excluded_keys=[])
    total = 0
    excluded_keys = Array.wrap(excluded_keys)
    largest_display_percentage_key = nil
    largest_display_percentage = 0
    total_display_percentage = 0
    new_gauge_hash = gauge_hash.deep_dup
    new_gauge_hash.each do |key, value|
      if value.nil? || value < 0
        value = 0
        new_gauge_hash[key] = value
      end
      total += value unless excluded_keys.include?(key)
    end

    new_gauge_hash.each do |key, value|
      percentage = total > 0 ? (value.to_f / total) * 100 : 0

      display_percentage = percentage.ceil
      display_percentage += display_percentage % 2

      new_gauge_hash[key] = {
        amount: value,
        percentage: percentage,
        display_percentage: display_percentage
      }
      unless excluded_keys.include?(key)
        if display_percentage >= largest_display_percentage
          largest_display_percentage = display_percentage
          largest_display_percentage_key = key
        end
        total_display_percentage += display_percentage
      end
    end
    new_gauge_hash[largest_display_percentage_key][:display_percentage] = (100 - (total_display_percentage - largest_display_percentage))
    new_gauge_hash
  end

  def process_recent_activities(activities)
    activity_data = []
    if activities
      i = 0
      activities.each do |activity|
        break if i > 4
        next unless activity[:instrument_type] == 'LC' ||
                    activity[:instrument_type] == 'ADVANCE' ||
                    activity[:instrument_type] == 'INVESTMENT'
        amount = activity[:current_par]
        description = activity[:product_description]
        transaction_number = activity[:transaction_number]
        maturity_date = activity[:maturity_date].to_date if activity[:maturity_date]
        event = case activity[:status]
        when 'TERMINATED'
          if activity[:instrument_type] == 'LC'
            t('dashboard.recent_activity.terminated_today')
          elsif activity[:instrument_type] == 'ADVANCE'
            activity[:termination_full_partial]
          else
            fhlb_date_standard_numeric(maturity_date)
          end
        when 'INTER_AMEND_STA'
          t('dashboard.recent_activity.amended_today')
        when 'EXPIRED'
          t('dashboard.recent_activity.expires_today')
        when 'MATURED'
          t('dashboard.recent_activity.matures_today')
        when 'VERIFIED'
          if activity[:product] == 'OPEN VRC'
            t('dashboard.open')
          else
            t('dashboard.recent_activity.matures_on', date: fhlb_date_standard_numeric(maturity_date))
          end
        when 'COLLATERAL_AUTH'
          t('dashboard.recent_activity.will_be_funded_on', date: fhlb_date_standard_numeric(activity[:funding_date]))
        when 'OPS_REVIEW', 'SEC_REVIEWED'
          t('dashboard.recent_activity.in_review')
        when 'EXECUTED'
          t('dashboard.recent_activity.matures_on', date: maturity_date)
        when 'PEND_TERM'
          if maturity_date
            t('dashboard.recent_activity.matures_on', date: maturity_date)
          else
            t('dashboard.open')
          end
        else
          if activity[:instrument_type] == 'INVESTMENT'
            if maturity_date == Time.zone.today
              t('dashboard.recent_activity.matures_today')
            else
              if maturity_date
                t('dashboard.recent_activity.matures_on', date: maturity_date)
              else
                t('dashboard.open')
              end
            end
          else
            if maturity_date == Time.zone.today
              t('global.today')
            else
              fhlb_date_standard_numeric(maturity_date)
            end
          end
        end
        if activity[:termination_full_partial] == 'PARTIAL PREPAYMENT'
          event = if activity[:sub_product].match(/(^|\s)VRC($|\s)/)
            t('dashboard.recent_activity.partial_repayment')
          else
            t('dashboard.recent_activity.partial_prepayment')
          end
          amount = activity[:termination_par]
          date = activity[:termination_date]
        end
        if activity[:product_description] == "LC" || activity[:product_description] == "LC LC LC"
          description = t('dashboard.recent_activity.letter_of_credit')
        end
        activity_data.push([description, amount, event, transaction_number])
        i += 1
      end
    end
    activity_data
  end

  def deferred_job_data
    raise "Invalid request: must be XMLHttpRequest (xhr) in order to be valid" unless request.xhr?
    param_name = "#{action_name}_job_id".to_sym
    raise ArgumentError, "No job id given for #{action_name}" unless params[param_name]
    job_status = JobStatus.find_by(id: params[param_name], user_id: current_user.id, status: JobStatus.statuses[:completed] )
    raise ActiveRecord::RecordNotFound unless job_status
    deferred_job_data = JSON.parse(job_status.result_as_string).clone
    job_status.destroy
    deferred_job_data
  end

  def populate_deferred_jobs_view_parameters(jobs_hash)
    jobs_hash.each do |name, args|
      job_klass = args.first
      path = args.last
      job_status = job_klass.perform_later(current_member_id, (request.uuid if defined?(request))).job_status
      job_status.update_attributes!(user_id: current_user.id)
      instance_variable_set("@#{name}_job_status_url", job_status_url(job_status))
      instance_variable_set("@#{name}_load_url", send(path, :"#{name}_job_id" => job_status.id))
    end
  end

  def calculate_borrowing_capacity_gauge(borrowing_capacity)
    # Nil check sbc collateral types
    borrowing_capacity[:sbc] = {} unless borrowing_capacity[:sbc]
    borrowing_capacity[:sbc][:collateral] = {} unless borrowing_capacity[:sbc][:collateral]
    borrowing_capacity[:sbc][:collateral][:agency] = {} unless borrowing_capacity[:sbc][:collateral][:agency]
    borrowing_capacity[:sbc][:collateral][:aaa] = {} unless borrowing_capacity[:sbc][:collateral][:aaa]
    borrowing_capacity[:sbc][:collateral][:aa] = {} unless borrowing_capacity[:sbc][:collateral][:aa]

    # Totals
    total_borrowing_capacity = borrowing_capacity[:total_borrowing_capacity].to_i

    # Standard
    total_standard_bc = borrowing_capacity[:net_plus_securities_capacity].to_i
    remaining_standard_bc = borrowing_capacity[:standard_excess_capacity].to_i
    used_standard_bc = total_standard_bc - remaining_standard_bc

    # Agency
    total_agency_bc = borrowing_capacity[:sbc][:collateral][:agency][:total_borrowing_capacity].to_i
    remaining_agency_bc = borrowing_capacity[:sbc][:collateral][:agency][:remaining_borrowing_capacity].to_i
    used_agency_bc = total_agency_bc - remaining_agency_bc

    # AAA
    total_aaa_bc = borrowing_capacity[:sbc][:collateral][:aaa][:total_borrowing_capacity].to_i
    remaining_aaa_bc = borrowing_capacity[:sbc][:collateral][:aaa][:remaining_borrowing_capacity].to_i
    used_aaa_bc = total_aaa_bc - remaining_aaa_bc

    # AA
    total_aa_bc = borrowing_capacity[:sbc][:collateral][:aa][:total_borrowing_capacity].to_i
    remaining_aa_bc = borrowing_capacity[:sbc][:collateral][:aa][:remaining_borrowing_capacity].to_i
    used_aa_bc = total_aa_bc - remaining_aa_bc

    if total_borrowing_capacity != 0
      borrowing_capacity_gauge = {
        total: total_borrowing_capacity,
        mortgages: total_standard_bc,
        agency: total_agency_bc,
        aaa: total_aaa_bc,
        aa: total_aa_bc
      }
      borrowing_capacity_gauge = calculate_gauge_percentages(borrowing_capacity_gauge, :total)
      borrowing_capacity_gauge[:mortgages][:breakdown] = {
        total: total_standard_bc,
        remaining: remaining_standard_bc,
        used: used_standard_bc
      }
      borrowing_capacity_gauge[:mortgages][:breakdown] = calculate_gauge_percentages(borrowing_capacity_gauge[:mortgages][:breakdown], :total)

      borrowing_capacity_gauge[:agency][:breakdown] = {
        total: total_agency_bc,
        remaining: remaining_agency_bc,
        used: used_agency_bc
      }
      borrowing_capacity_gauge[:agency][:breakdown] = calculate_gauge_percentages(borrowing_capacity_gauge[:agency][:breakdown], :total)

      borrowing_capacity_gauge[:aaa][:breakdown] = {
        total: total_aaa_bc,
        remaining: remaining_aaa_bc,
        used: used_aaa_bc
      }
      borrowing_capacity_gauge[:aaa][:breakdown] = calculate_gauge_percentages(borrowing_capacity_gauge[:aaa][:breakdown], :total)
      borrowing_capacity_gauge[:aa][:breakdown] = {
        total: total_aa_bc,
        remaining: remaining_aa_bc,
        used: used_aa_bc
      }
      borrowing_capacity_gauge[:aa][:breakdown] = calculate_gauge_percentages(borrowing_capacity_gauge[:aa][:breakdown], :total)
      borrowing_capacity_gauge[:total][:standard_percentage] = borrowing_capacity_gauge[:mortgages][:percentage]
      borrowing_capacity_gauge[:total][:sbc_percentage] = (borrowing_capacity_gauge[:agency][:percentage] + borrowing_capacity_gauge[:aaa][:percentage] + borrowing_capacity_gauge[:aa][:percentage])
    else
      borrowing_capacity_gauge = calculate_gauge_percentages({total: 0})
      borrowing_capacity_gauge[:total][:standard_percentage] = 0
      borrowing_capacity_gauge[:total][:sbc_percentage] = 0
    end
    borrowing_capacity_gauge
  end
end