class ReportsController < ApplicationController
  include DatePickerHelper
  include CustomFormattingHelper
  include ActionView::Helpers::NumberHelper

  # Mapping of current reports onto flags defined in MembersService
  ADVANCES_DETAIL_WEB_FLAGS = [MembersService::ADVANCES_DETAIL_DATA, MembersService::ADVANCES_DETAIL_HISTORY]
  BORROWING_CAPACITY_WEB_FLAGS = [MembersService::COLLATERAL_REPORT_DATA]
  CAPITAL_STOCK_ACTIVITY_WEB_FLAGS = [MembersService::CURRENT_SECURITIES_POSITION, MembersService::CAPSTOCK_REPORT_BALANCE]
  HISTORICAL_PRICE_INDICATIONS_WEB_FLAGS = [MembersService::IRDB_RATES_DATA]
  SETTLEMENT_TRANSACTION_ACCOUNT_WEB_FLAGS = [MembersService::STA_BALANCE_AND_RATE_DATA, MembersService::STA_DETAIL_DATA]
  CASH_PROJECTIONS_WEB_FLAGS = [MembersService::CASH_PROJECTIONS_DATA]
  DIVIDEND_STATEMENT_WEB_FLAGS = [MembersService::CAPSTOCK_REPORT_DIVIDEND_TRANSACTION, MembersService::CAPSTOCK_REPORT_DIVIDEND_STATEMENT]
  SECURITIES_SERVICES_STATMENT_WEB_FLAGS = [MembersService::SECURITIESBILLSTATEMENT]
  LETTERS_OF_CREDIT_WEB_FLAGS = [MembersService::LETTERS_OF_CREDIT_DETAIL_REPORT]
  SECURITIES_TRANSACTION_WEB_FLAGS = [MembersService::SECURITIES_TRANSACTION_DATA]

  before_action do
    @member_name = current_member_name
  end

  def index
    @reports = {
      price_indications: {
        current: {
          updated: t('global.daily'),
          available_history: t('global.current_day'),
          summary: t('reports.price_indications.current.summary', phone_number: fhlb_formatted_phone_number('8004443452'))
        },
        historical: {
          updated: t('global.daily'),
          available_history: t('global.various'),
          route: reports_historical_price_indications_path
        }
      },
      credit: {
        advances_detail: {
          updated: t('global.daily'),
          available_history: t('global.all'),
          route: reports_advances_path
        },
        interest_rate: {
          updated: t('global.daily'),
          available_history: t('reports.history.months12'),
          route: reports_interest_rate_resets_path
        },
        letters_of_credit: {
          updated: t('global.daily'),
          available_history: t('global.all'),
          route: reports_letters_of_credit_path
        },
        forward_commitments: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        parallel_shift: {
          updated: t('global.monthly'),
          available_history: t('global.all')
        }
      },
      collateral: {
        borrowing_capacity: {
          updated: t('global.daily'),
          available_history: t('global.all'),
          route: reports_borrowing_capacity_path
        },
        mcu: {
          updated: t('global.daily'),
          available_history: t('global.all')
        }
      },
      capital_stock: {
        activity: {
          updated: t('global.daily'),
          available_history: t('reports.history.months12'),
          route: reports_capital_stock_activity_path
        },
        dividend_statement: {
          updated: t('global.quarterly'),
          available_history: t('reports.history.months36'),
          route: reports_dividend_statement_path
        }
      },
      settlement: {
        account: {
          updated: t('global.daily'),
          available_history: t('global.all'),
          route: reports_settlement_transaction_account_path
        }
      },
      securities: {
        transactions: {
          updated: t('reports.twice_daily'),
          available_history: t('global.all'),
          route: reports_securities_transactions_path
        },
        cash_projections: {
          updated: t('global.daily'),
          available_history: t('global.current_day'),
          route: reports_cash_projections_path
        },
        current: {
          updated: t('reports.continuously'),
          available_history: t('global.current_day')
        },
        monthly: {
          updated: t('global.monthly'),
          available_history: t('reports.history.months18')
        },
        services_monthly: {
          updated: t('global.monthly'),
          available_history: t('reports.history.months18'),
          route: reports_securities_services_statement_path
        }
      },
      authorizations: {
        user: {
          updated: t('reports.continuously'),
          available_history: t('global.current_day'),
          route: reports_authorizations_path
        }
      }
    }
  end

  def capital_stock_activity
    default_dates = default_dates_hash
    member_balances = MemberBalanceService.new(current_member_id, request)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    if report_disabled?(CAPITAL_STOCK_ACTIVITY_WEB_FLAGS)
      @capital_stock_activity = {}
    else
      @capital_stock_activity = member_balances.capital_stock_activity(@start_date, @end_date)
      raise StandardError, "There has been an error and ReportsController#capital_stock_activity has encountered nil. Check error logs." if @capital_stock_activity.nil?
    end
    @picker_presets = date_picker_presets(@start_date, @end_date)
  end

  def borrowing_capacity
    member_balances = MemberBalanceService.new(current_member_id, request)
    date = params[:end_date] || Time.zone.now.to_date
    if report_disabled?(BORROWING_CAPACITY_WEB_FLAGS)
      @borrowing_capacity_summary = {}
    else
      @borrowing_capacity_summary = member_balances.borrowing_capacity_summary(date.to_date)
      raise StandardError, "There has been an error and ReportsController#borrowing_capacity has encountered nil. Check error logs." if @borrowing_capacity_summary.nil?
    end
  end

  def settlement_transaction_account
    default_dates = default_dates_hash
    member_balances = MemberBalanceService.new(current_member_id, request)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    @daily_balance_key = MemberBalanceService::DAILY_BALANCE_KEY
    @picker_presets = date_picker_presets(@start_date, @end_date)
    @filter_options = [
        [t('global.all'), 'all'],
        [t('global.debits'), 'debit'],
        [t('global.credits'), 'credit'],
        [t('global.daily_balances'), 'balance']
    ]
    filter_param = params[:sta_filter]
    @filter_options.each do |option|
      if option[1] == filter_param
        @filter = filter_param
        @filter_text = option[0]
        break
      end
    end
    # default filter to 'all' if invalid filter param was passed
    @filter ||= @filter_options[0][1]
    @filter_text ||= @filter_options[0][0]
    if report_disabled?(SETTLEMENT_TRANSACTION_ACCOUNT_WEB_FLAGS)
      @settlement_transaction_account = {}
    else
      @settlement_transaction_account = member_balances.settlement_transaction_account(@start_date, @end_date, @filter)
      raise StandardError, "There has been an error and ReportsController#settlement_transaction_account has encountered nil. Check error logs." if @settlement_transaction_account.nil?
    end
    @show_ending_balance = false
    if @settlement_transaction_account[:activities] && @settlement_transaction_account[:activities].length > 0
      @show_ending_balance = @end_date != @settlement_transaction_account[:activities][0][:trans_date].to_date || @settlement_transaction_account[:activities][0][:balance].blank?
    end
  end

  def advances_detail
    @start_date = (params[:start_date] || Time.zone.now.to_date).to_date
    member_balances = MemberBalanceService.new(current_member_id, request)
    @advances_detail = member_balances.advances_details(@start_date)
    raise StandardError, "There has been an error and ReportsController#advances_detail has encountered nil. Check error logs." if @advances_detail.nil?
    @picker_presets = date_picker_presets(@start_date)
    if report_disabled?(ADVANCES_DETAIL_WEB_FLAGS)
      @advances_detail = {}
    else
      @advances_detail = member_balances.advances_details(@start_date)
      raise StandardError, "There has been an error and ReportsController#advances_detail has encountered nil. Check error logs." if @advances_detail.nil?
      # prepayment fee indication for detail view
      @advances_detail[:advances_details].each_with_index do |advance, i|
        case advance[:notes]
          when 'unavailable_online'
            @advances_detail[:advances_details][i][:prepayment_fee_indication_notes] = t('reports.pages.advances_detail.unavailable_online')
          when 'not_applicable_to_vrc'
            @advances_detail[:advances_details][i][:prepayment_fee_indication_notes] = t('reports.pages.advances_detail.not_applicable_to_vrc')
          when 'prepayment_fee_restructure'
            @advances_detail[:advances_details][i][:prepayment_fee_indication_notes] = t('reports.pages.advances_detail.prepayment_fee_restructure_html', date: fhlb_date_standard_numeric(advance[:structure_product_prepay_valuation_date].to_date))
          else
            @advances_detail[:advances_details][i][:prepayment_fee_indication_notes] = t('reports.pages.advances_detail.unavailable_for_past_dates') unless advance[:prepayment_fee_indication]
        end
      end
    end
    @advances_detail[:advances_details].sort! { |a, b| a[:trade_date] <=> b[:trade_date] } if @advances_detail[:advances_details]

    export_format = params[:export_format]
    if export_format == 'pdf'
      job_status = RenderReportPDFJob.perform_later(current_member_id, 'advances_detail', 'advances', {start_date: @start_date.to_s}).job_status
    elsif export_format == 'xlsx'
      job_status = RenderReportExcelJob.perform_later(current_member_id, 'advances_detail', "advances-#{@start_date.to_s}", {start_date: @start_date.to_s}).job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    end
  end

  def current_price_indications
    rate_service = RatesService.new(request)
    member_balances = MemberBalanceService.new(current_member_id, request)

    #sta data
    @sta_data = member_balances.settlement_transaction_rate
    @sta_table_data = {
        :row_name => t('reports.pages.price_indications.current.sta_rate'),
        :row_value => @sta_data['sta_rate']
    }

    #vrc headers
    column_headings = [t('reports.pages.price_indications.current.advance_maturity'), t('reports.pages.price_indications.current.overnight_fed_funds_benchmark'), t('reports.pages.price_indications.current.basis_point_spread_to_benchmark'), t('reports.pages.price_indications.current.advance_rate')]
    #vrc data for standard collateral
    @standard_vrc_data = rate_service.current_price_indications('standard', 'vrc')
    columns = @standard_vrc_data.collect do |row|
      case row[0]
      when 'overnight_fed_funds_benchmark', 'advance_rate'
        type = :rate
      when 'basis_point_spread_to_benchmark'
        type = :basis_point
      else
        type = nil
      end
      {value: row[1], type: type}
    end
    rows = [{columns: columns}]
    @standard_vrc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }
    #vrc data for sbc collateral
    @sbc_vrc_data = rate_service.current_price_indications('sbc', 'vrc')
    columns = @sbc_vrc_data.collect do |row|
      case row[0]
      when 'overnight_fed_funds_benchmark', 'advance_rate'
        type = :rate
      when 'basis_point_spread_to_benchmark'
        type = :basis_point
      else
        type = nil
      end
      {value: row[1], type: type}
    end
    rows = [{columns: columns}]
    @sbc_vrc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }

    #frc headers
    column_headings = [t('reports.pages.price_indications.current.advance_maturity'), t('reports.pages.price_indications.current.treasury_benchmark_maturity'), t('reports.pages.price_indications.current.nominal_yield_of_benchmark'), t('reports.pages.price_indications.current.basis_point_spread_to_benchmark'), t('reports.pages.price_indications.current.advance_rate')]
    #frc data for standard collateral
    @standard_frc_data = rate_service.current_price_indications('standard', 'frc')
    rows = @standard_frc_data.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='advance_maturity' || value[0]=='treasury_benchmark_maturity'
          columns << {value: value[1]}
        elsif value[0]=='basis_point_spread_to_benchmark'
          columns << {type: :basis_point, value: value[1]}
        else
          columns << {type: :rate, value: value[1]}
        end
      end
      {columns: columns}
    end
    @standard_frc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }
    #frc data for sbc collateral
    @sbc_frc_data = rate_service.current_price_indications('sbc', 'frc')
    rows = @sbc_frc_data.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='advance_maturity' || value[0]=='treasury_benchmark_maturity'
          columns << {value: value[1]}
        elsif value[0]=='basis_point_spread_to_benchmark'
          columns << {type: :basis_point, value: value[1]}
        else
          columns << {type: :rate, value: value[1]}
        end
      end
      {columns: columns}
    end
    @sbc_frc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }

    #arc headers for standard collateral
    column_headings = [t('reports.pages.price_indications.current.advance_maturity'), t('reports.pages.price_indications.current.1_month_libor'), t('reports.pages.price_indications.current.3_month_libor'), t('reports.pages.price_indications.current.6_month_libor'), t('reports.pages.price_indications.current.prime')]
    #arc data for standard collateral
    @standard_arc_data = rate_service.current_price_indications('standard', 'arc')
    rows = @standard_arc_data.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='advance_maturity'
          columns << {value: value[1]}
        else
          columns << {type: :basis_point, value: value[1]}
        end
      end
      {columns: columns}
    end
    @standard_arc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }
    #arc headers for sbc collateral
    column_headings = [t('reports.pages.price_indications.current.advance_maturity'), t('reports.pages.price_indications.current.1_month_libor'), t('reports.pages.price_indications.current.3_month_libor'), t('reports.pages.price_indications.current.6_month_libor')]
    #arc data for sbc collateral
    @sbc_arc_data = rate_service.current_price_indications('sbc', 'arc')
    rows = @sbc_arc_data.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='advance_maturity'
          columns << {value: value[1]}
        elsif value[0]=='1_month_libor' || value[0]=='3_month_libor' || value[0]=='6_month_libor'
          columns << {type: :basis_point, value: value[1]}
        end
      end
      {columns: columns}
    end
    @sbc_arc_table_data = {
        :column_headings => column_headings,
        :rows => rows
    }
  end

  def historical_price_indications
    rate_service = RatesService.new(request)
    default_dates = default_dates_hash
    @start_date = ((params[:start_date] || default_dates[:this_year_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:today])).to_date
    preset_options = {
        :first_preset => {
            :label => I18n.t('global.last_year'),
            :start_date => default_dates[:last_year_start],
            :end_date => default_dates[:last_year_end]
        },
        :second_preset => {
            :label => I18n.t('global.year_to_date'),
            :start_date => default_dates[:this_year_start],
            :end_date => default_dates[:today]
        }
    }
    @picker_presets = date_picker_presets(@start_date, @end_date, preset_options)
    
    @collateral_type_options = [
        [t('reports.pages.price_indications.standard_credit_program'), 'standard'],
        [t('reports.pages.price_indications.sbc_program'), 'sbc']
    ]
    collateral_type = params[:historical_price_collateral_type]
    @collateral_type_options.each do |option|
      if option[1] == collateral_type
        @collateral_type = collateral_type
        @collateral_type_text = option[0]
        break
      end
    end
    @collateral_type ||= @collateral_type_options.first.last
    @collateral_type_text ||= @collateral_type_options.first.first
    @credit_type_options = [
        [t('reports.pages.price_indications.frc.dropdown'), 'frc'],
        [t('reports.pages.price_indications.vrc.dropdown'), 'vrc'],
        [t('reports.pages.price_indications.1m_libor.dropdown'), '1m_libor'],
        [t('reports.pages.price_indications.3m_libor.dropdown'), '3m_libor'],
        [t('reports.pages.price_indications.6m_libor.dropdown'), '6m_libor']
    ]
    if @collateral_type == 'standard'
      @credit_type_options.push(
        [t('reports.pages.price_indications.daily_prime.dropdown'), 'daily_prime'],
        [t('reports.pages.price_indications.embedded_cap.dropdown'), 'embedded_cap']
      )
    end
    credit_type = params[:historical_price_credit_type]
    @credit_type_options.each do |option|
      if option[1] == credit_type
        @credit_type = credit_type
        @credit_type_text = option[0]
        break
      end
    end
    @credit_type ||= @credit_type_options.first.last
    @credit_type_text ||= @credit_type_options.first.first

    if report_disabled?(HISTORICAL_PRICE_INDICATIONS_WEB_FLAGS)
      @historical_price_indications = {}
    else
      @historical_price_indications = rate_service.historical_price_indications(@start_date, @end_date, @collateral_type, @credit_type)
      raise StandardError, "There has been an error and ReportsController#historical_price_indications has encountered nil. Check error logs." if @historical_price_indications.nil?
    end

    case @credit_type.to_sym
    when :frc
      column_heading_keys = RatesService::HISTORICAL_FRC_TERM_MAPPINGS.values
      terms = RatesService::HISTORICAL_FRC_TERM_MAPPINGS.keys
    when :vrc
      column_heading_keys = RatesService::HISTORICAL_VRC_TERM_MAPPINGS.values
      terms = RatesService::HISTORICAL_VRC_TERM_MAPPINGS.keys
    when *RatesService::ARC_CREDIT_TYPES
      table_heading = I18n.t("reports.pages.price_indications.#{@credit_type}.table_heading") unless @credit_type == :daily_prime
      column_heading_keys = RatesService::HISTORICAL_ARC_TERM_MAPPINGS.values
      terms = RatesService::HISTORICAL_ARC_TERM_MAPPINGS.keys
      # TODO add statement for 'embedded_cap' when it is rigged up
    end

    column_headings = []
    column_sub_headings = []
    if (@credit_type.to_sym == :daily_prime)
      column_heading_keys.each do |key|
        column_headings << I18n.t("global.full_dates.#{key}")
        column_sub_headings = [fhlb_add_unit_to_table_header(I18n.t("reports.pages.price_indications.daily_prime.benchmark_index"), '%'), I18n.t("reports.pages.price_indications.daily_prime.basis_point_spread")]
      end
      column_sub_headings_first =  I18n.t('global.date')
    else
      column_heading_keys.each do |key|
        column_headings << I18n.t("global.dates.#{key}")
      end
      column_headings.insert(0, I18n.t('global.date'))
    end

    rows = if @historical_price_indications[:rates_by_date]
      @historical_price_indications[:rates_by_date] = add_rate_objects_for_all_terms(@historical_price_indications[:rates_by_date], terms, @credit_type.to_sym)
      if (@credit_type.to_sym == :daily_prime)
        @historical_price_indications[:rates_by_date].collect do |row|
          columns = []
          # need to replicate rate data for display purposes
          row[:rates_by_term].each_with_index do |column, i|
            next if i == 0
            columns <<  {type: row[:rates_by_term][0][:type].to_sym, value: row[:rates_by_term][0][:value]}
            columns <<  {type: column[:type].to_sym, value: column[:value] }
          end
          {date: row[:date], columns: columns }
        end
      else
        @historical_price_indications[:rates_by_date].collect do |row|
          {date: row[:date], columns: row[:rates_by_term].collect {|column| {type: column[:type].to_sym, value: column[:value] } } }
        end
      end
    else
      []
    end
    @table_data = {
      :table_heading => table_heading,
      :column_headings => column_headings,
      :column_sub_headings => column_sub_headings,
      :column_sub_headings_first => column_sub_headings_first,
      :rows => rows
    }
  end

  def cash_projections
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(CASH_PROJECTIONS_WEB_FLAGS)
      @cash_projections = {}
    else
      @cash_projections = member_balances.cash_projections
      raise StandardError, "There has been an error and ReportsController#cash_projections has encountered nil. Check error logs." if @cash_projections.nil?
    end
    @as_of_date = @cash_projections[:as_of_date].to_date if @cash_projections[:as_of_date]
  end

  def interest_rate_resets
    rate_service = RatesService.new(request)
    @start_date = (Time.zone.now.to_date).to_date
    column_headings = [t('reports.pages.interest_rate_resets.effective_date'), t('reports.pages.interest_rate_resets.advance_number'), t('reports.pages.interest_rate_resets.prior_rate'), t('reports.pages.interest_rate_resets.new_rate'), t('reports.pages.interest_rate_resets.next_reset')]
    irr_data = rate_service.interest_rate_resets
    rows = irr_data.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='prior_rate' || value[0]=='new_rate'
          columns << {type: :index, value: value[1]}
        elsif value[0]=='effective_date'
          columns << {type: :date, value: value[1]}
        else
          columns << {value: value[1]}
        end
      end
      {columns: columns}
    end
    @irr_table_data = {
      :column_headings => column_headings,
      :rows => rows
    }
  end

  def dividend_statement
    member_balances = MemberBalanceService.new(current_member_id, request)
    @dividend_statement_details = {
      column_headings: [
        {title: t('global.issue_date'), sortable: true},
        {title: t('global.certificate_sequence'), sortable: true},
        {title: t('global.start_date'), sortable: true},
        {title: t('global.end_date'), sortable: true},
        {title: t('global.shares_outstanding'), sortable: true},
        {title: t('reports.pages.dividend_statement.headers.days_outstanding'), sortable: true},
        {title: t('reports.pages.dividend_statement.headers.average_shares'), sortable: true},
        {title: t('reports.pages.dividend_statement.headers.dividend'), sortable: true}
      ]
    }
    if report_disabled?(DIVIDEND_STATEMENT_WEB_FLAGS)
      @dividend_statement = {}
      @dividend_statement_details[:rows] = []
    else
      @dividend_statement = member_balances.dividend_statement(Time.zone.now.to_date)
      raise StandardError, "There has been an error and ReportsController#dividend_statement has encountered nil. Check error logs." if @dividend_statement.nil?
      @dividend_statement_details[:rows] = @dividend_statement[:details].collect do |detail|
        {
          columns: [
            {value: detail[:issue_date], type: :date},
            {value: detail[:certificate_sequence], type: nil},
            {value: detail[:start_date], type: :date},
            {value: detail[:end_date], type: :date},
            {value: detail[:shares_outstanding], type: :number},
            {value: detail[:days_outstanding], type: :number},
            {value: detail[:average_shares_outstanding], type: :shares_fractional},
            {value: detail[:dividend], type: :currency}
          ]
        }
      end
      @dividend_statement_details[:footer] = [
        { value: t('global.totals'), colspan: 6},
        { value: @dividend_statement[:average_shares_outstanding], type: :shares_fractional},
        { value: @dividend_statement[:total_dividend], type: :currency}
      ]
    end
  end

  def securities_services_statement
    @start_date = (params[:start_date] || Time.zone.now).to_date
    if report_disabled?(SECURITIES_SERVICES_STATMENT_WEB_FLAGS)
      @statement = {}
    else
      member_balances = MemberBalanceService.new(current_member_id, request)
      @statement = member_balances.securities_services_statement(@start_date)
      raise StandardError, "There has been an error and ReportsController#securities_services_statement has encountered nil. Check error logs." if @statement.nil?
    end
    @picker_presets = date_picker_presets(@start_date)
  end

  def letters_of_credit
    if report_disabled?(LETTERS_OF_CREDIT_WEB_FLAGS)
      letters_of_credit = {}
    else
      member_balances = MemberBalanceService.new(current_member_id, request)
      letters_of_credit = member_balances.letters_of_credit
      raise StandardError, "There has been an error and ReportsController#letters_of_credit has encountered nil. Check error logs." if letters_of_credit.nil?
    end
    @as_of_date = letters_of_credit[:as_of_date]
    @total_current_par = letters_of_credit[:total_current_par]
    rows = if letters_of_credit[:rows]
      letters_of_credit[:rows].collect do |row|
        {
          columns: [
            {value: row[:lc_number], type: nil},
            {value: row[:current_par], type: :currency_whole},
            {value: row[:maintenance_charge], type: :number},
            {value: row[:trade_date], type: :date, classes: [:'report-cell-right']},
            {value: row[:settlement_date], type: :date, classes: [:'report-cell-right']},
            {value: row[:maturity_date], type: :date, classes: [:'report-cell-right']},
            {value: row[:description], type: nil}
          ]
        }
      end
    else
      {}
    end
    @loc_table_data = {
      column_headings: [t('reports.pages.letters_of_credit.headers.lc_number'), fhlb_add_unit_to_table_header(t('common_table_headings.current_par'), '$'), t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), t('common_table_headings.trade_date'), t('common_table_headings.settlement_date'), t('common_table_headings.maturity_date'), t('common_table_headings.description')],
      rows: rows,
      footer: [{value: t('global.total')}, {value: @total_current_par, type: :currency_whole}, {value: nil, colspan: 5}]
    }
  end

  def securities_transactions
    @start_date = (params[:start_date] || Time.zone.now.to_date).to_date
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(SECURITIES_TRANSACTION_WEB_FLAGS)
      securities_transactions = {}
      securities_transactions[:transactions] = []
    else
      securities_transactions = member_balances.securities_transactions(@start_date)
      raise StandardError, "There has been an error and ReportsController#securities_transactions has returned nil. Check error logs." if securities_transactions.blank?
    end
    @picker_presets = date_picker_presets(@start_date)
    @total_net = securities_transactions[:total_net]
    @final = securities_transactions[:final]
    column_headings = [t('reports.pages.securities_transactions.custody_account_no'), t('reports.pages.securities_transactions.cusip'), t('reports.pages.securities_transactions.transaction_code'), t('reports.pages.securities_transactions.security_description'), t('reports.pages.securities_transactions.units'), t('reports.pages.securities_transactions.maturity_date'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.payment_or_principal'), '$'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.interest'), '$'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.total'), '$')]
    rows = securities_transactions[:transactions].collect do |row|
      columns = []
      row.each do |value|
        case value[0]
        when 'units'
          columns << {type: :basis_point, value: value[1]}
        when 'maturity_date'
          columns << {type: :date, value: value[1]}
        when 'payment_or_principal', 'interest', 'total'
          columns << {type: :rate, value: value[1]}
        when 'custody_account_no'
          if row['new_transaction']
            columns << {type: nil, value: "#{value[1]}*"}
          else
            columns << {type: nil, value: value[1]}
          end
        when 'cusip', 'transaction_code', 'security_description'
          columns << {type: nil, value: value[1]}
        end
      end
      {columns: columns}
    end
    footer = [
        { value: t('reports.pages.securities_transactions.total_net_amount'), colspan: 6},
        { value: securities_transactions[:total_payment_or_principal],  type: :currency},
        { value: securities_transactions[:total_interest], type: :currency},
        { value: @total_net, type: :currency}
    ]
    @securities_transactions_table_data = {
        :column_headings => column_headings,
        :rows => rows,
        :footer => footer
    }
  end

  def authorizations
    @authorizations_filter = params['authorizations_filter'] || 'all'
    users = MembersService.new(request).signers_and_users(current_member_id).try(:sort_by, &:display_name) || []
    rows = []
    users.each do |user|
      user_roles = roles_for_signers(user)
      if @authorizations_filter == 'user' && user_roles.include?(t('user_roles.user.title'))
        rows << {columns: [{type: nil, value: user.display_name}, {type: :list, value: user_roles}]}
      else
        next if user_roles.empty? || (@authorizations_filter != 'all' && !user.roles.include?(@authorizations_filter))
        rows << {columns: [{type: nil, value: user.display_name}, {type: :list, value: user_roles}]}
      end
    end
    @authorizations_table_data = {
      :column_headings => [t('user_roles.user.title'), t('reports.authorizations.title')],
      :rows => rows
    }
    @roles_dropdown_options = [
      [t('user_roles.all_authorizations'), 'all'],
      [t('user_roles.resolution.dropdown'), User::Roles::SIGNER_MANAGER],
      [t('user_roles.entire_authority.dropdown'), User::Roles::SIGNER_ENTIRE_AUTHORITY],
      [t('user_roles.affordable_housing.title'), User::Roles::AFFORDABILITY_SIGNER],
      [t('user_roles.collateral.title'), User::Roles::COLLATERAL_SIGNER],
      [t('user_roles.money_market.title'), User::Roles::MONEYMARKET_SIGNER],
      [t('user_roles.interest_rate_derivatives.title'), User::Roles::DERIVATIVES_SIGNER],
      [t('user_roles.securities.title'), User::Roles::SECURITIES_SIGNER],
      [t('user_roles.wire_transfer.title'), User::Roles::WIRE_SIGNER],
      [t('user_roles.access_manager.title'), User::Roles::ACCESS_MANAGER],
      [t('user_roles.etransact.title'), User::Roles::ETRANSACT_SIGNER],
      [t('user_roles.user.title'), 'user']
    ]
    @roles_dropdown_options.each do |option|
      if option[1] == @authorizations_filter
        @authorizations_filter_text = option[0]
        break
      end
    end
  end

  private
  def report_disabled?(report_flags)
    member_info = MembersService.new(request)
    member_info.report_disabled?(current_member_id, report_flags)
  end

  def add_rate_objects_for_all_terms(rates_by_date_array, terms, credit_type)
    terms.unshift('1d') if credit_type == :daily_prime
    new_array = []
    rates_by_date_array.each do |rate_by_date_obj|
      rate_by_date_obj = rate_by_date_obj
      new_array << {date: rate_by_date_obj[:date], rates_by_term: []}
      terms.each do |term|
        rate_obj = rate_by_date_obj[:rates_by_term].select {|rate_obj| rate_obj[:term] == term.to_s.upcase}.first || {
          term: term.to_s.upcase,
          type: 'index', # placeholder type
          value: nil,
          day_count_basis: nil,
          pay_freq: nil
        }
        new_array.last[:rates_by_term] << rate_obj.with_indifferent_access
      end
    end
    new_array
  end

  def roles_for_signers(signer)
    roles = signer.roles.collect do |role|
      if role == User::Roles::ACCESS_MANAGER
        t('user_roles.access_manager.title')
      elsif role == User::Roles::SIGNER_MANAGER
        t('user_roles.resolution.title')
      elsif role == User::Roles::SIGNER_ENTIRE_AUTHORITY
        t('user_roles.entire_authority.title')
      elsif role == User::Roles::AFFORDABILITY_SIGNER
        t('user_roles.affordable_housing.title')
      elsif role == User::Roles::COLLATERAL_SIGNER
        t('user_roles.collateral.title')
      elsif role == User::Roles::MONEYMARKET_SIGNER
        t('user_roles.money_market.title')
      elsif role == User::Roles::DERIVATIVES_SIGNER
        t('user_roles.interest_rate_derivatives.title')
      elsif role == User::Roles::SECURITIES_SIGNER
        t('user_roles.securities.title')
      elsif role == User::Roles::WIRE_SIGNER
        t('user_roles.wire_transfer.title')
      elsif role == User::Roles::ETRANSACT_SIGNER
        t('user_roles.etransact.title')
      end
    end
    roles.compact!
    roles.present? ? roles : [t('user_roles.user.title')]
  end

end