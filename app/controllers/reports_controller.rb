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
  PARALLEL_SHIFT_WEB_FLAGS = [MembersService::ADVANCES_DETAIL_DATA]
  CURRENT_SECURITIES_POSITION_WEB_FLAG = [MembersService::CURRENT_SECURITIES_POSITION]
  MONTHLY_SECURITIES_WEB_FLAGS = [MembersService::MONTHLY_SECURITIES_POSITION]
  FORWARD_COMMITMENTS_WEB_FLAG = [MembersService::ADVANCES_DETAIL_DATA]
  CAPITAL_STOCK_AND_LEVERAGE_WEB_FLAGS = [MembersService::FHLB_STOCK_DATA]
  ACCOUNT_SUMMARY_WEB_FLAGS = [MembersService::FINANCING_AVAILABLE_DATA, MembersService::CREDIT_OUTSTANDING_DATA, MembersService::COLLATERAL_HIGHLIGHTS_DATA, MembersService::FHLB_STOCK_DATA]
  INTEREST_RATE_RESETS_WEB_FLAGS = [MembersService::ADVANCES_DETAIL_DATA]

  AUTHORIZATIONS_MAPPING = {
    User::Roles::SIGNER_MANAGER => I18n.t('user_roles.resolution.title'),
    User::Roles::SIGNER_ENTIRE_AUTHORITY => I18n.t('user_roles.entire_authority.title'),
    User::Roles::ADVANCE_SIGNER => I18n.t('user_roles.advances.title'),
    User::Roles::AFFORDABILITY_SIGNER => I18n.t('user_roles.affordable_housing.title'),
    User::Roles::COLLATERAL_SIGNER => I18n.t('user_roles.collateral.title'),
    User::Roles::MONEYMARKET_SIGNER => I18n.t('user_roles.money_market.title'),
    User::Roles::DERIVATIVES_SIGNER => I18n.t('user_roles.interest_rate_derivatives.title'),
    User::Roles::SECURITIES_SIGNER => I18n.t('user_roles.securities.title'),
    User::Roles::WIRE_SIGNER => I18n.t('user_roles.wire_transfer.title'),
    User::Roles::ACCESS_MANAGER => I18n.t('user_roles.access_manager.title'),
    User::Roles::ETRANSACT_SIGNER => I18n.t('user_roles.etransact.title')
  }

  AUTHORIZATIONS_DROPDOWN_MAPPING = {
    'all' => I18n.t('user_roles.all_authorizations'),
    User::Roles::SIGNER_MANAGER => I18n.t('user_roles.resolution.dropdown'),
    User::Roles::SIGNER_ENTIRE_AUTHORITY => I18n.t('user_roles.entire_authority.dropdown'),
    User::Roles::ADVANCE_SIGNER => I18n.t('user_roles.advances.title'),
    User::Roles::AFFORDABILITY_SIGNER => I18n.t('user_roles.affordable_housing.title'),
    User::Roles::COLLATERAL_SIGNER => I18n.t('user_roles.collateral.title'),
    User::Roles::MONEYMARKET_SIGNER => I18n.t('user_roles.money_market.title'),
    User::Roles::DERIVATIVES_SIGNER => I18n.t('user_roles.interest_rate_derivatives.title'),
    User::Roles::SECURITIES_SIGNER => I18n.t('user_roles.securities.title'),
    User::Roles::WIRE_SIGNER => I18n.t('user_roles.wire_transfer.title'),
    User::Roles::ACCESS_MANAGER => I18n.t('user_roles.access_manager.title'),
    User::Roles::ETRANSACT_SIGNER => I18n.t('user_roles.etransact.title'),
    'user' => I18n.t('user_roles.user.title')
  }

  DATE_PICKER_FILTERS = {
    end_of_month: 'endOfMonth',
    end_of_quarter: 'endOfQuarter'
  }

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
          available_history: t('global.all'),
          path: reports_forward_commitments_path
        },
        parallel_shift: {
          updated: t('global.monthly'),
          available_history: t('global.all'),
          route: reports_parallel_shift_path
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
        capital_stock_and_leverage: {
          updated: '',
          available_history: '',
          route: reports_capital_stock_and_leverage_path
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
          available_history: t('global.current_day'),
          path: reports_current_securities_position_path
        },
        monthly: {
          updated: t('global.monthly'),
          available_history: t('reports.history.months18'),
          path: reports_monthly_securities_position_path
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
    @date = params[:end_date] || Time.zone.now.to_date
    export_format = params[:export_format]
    @report_name = t('global.borrowing_capacity')

    if export_format == 'pdf'
      job_status = RenderReportPDFJob.perform_later(current_member_id, 'borrowing_capacity', 'borrowing-capacity', {end_date: @date.to_s}).job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
      member_balances = MemberBalanceService.new(current_member_id, request)
      if report_disabled?(BORROWING_CAPACITY_WEB_FLAGS)
        @borrowing_capacity_summary = {}
      else
        @borrowing_capacity_summary = member_balances.borrowing_capacity_summary(@date.to_date)
        raise StandardError, "There has been an error and ReportsController#borrowing_capacity has encountered nil. Check error logs." if @borrowing_capacity_summary.nil?
      end
    end
  end

  def settlement_transaction_account
    default_dates = default_dates_hash
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    export_format = params[:export_format]
    @report_name = t('reports.pages.settlement_transaction_account.title')
    member_balances = MemberBalanceService.new(current_member_id, request)
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
    if export_format == 'pdf'
      job_status = RenderReportPDFJob.perform_later(current_member_id, 'settlement_transaction_account', 'settlement-transaction-account', {start_date: @start_date.to_s, end_date: @end_date.to_s, sta_filter: @filter}).job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
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
  end

  def advances_detail
    @start_date = (params[:start_date] || Time.zone.now.to_date).to_date
    member_balances = MemberBalanceService.new(current_member_id, request)
    @advances_detail = member_balances.advances_details(@start_date)
    @report_name = t('global.advances')
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
    today = Time.zone.today
    @report_name = t('reports.pages.price_indications.current.title')
    export_format = params[:export_format]
    if export_format == 'xlsx'
      job_status = RenderReportExcelJob.perform_later(current_member_id, 'current_price_indications', "current-price-indications-#{today.to_s}").job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
      rate_service = RatesService.new(request)
      member_balances = MemberBalanceService.new(current_member_id, request)

      #sta data
      @sta_data = member_balances.settlement_transaction_rate
      @sta_table_data = {
        :row_name => t('reports.pages.price_indications.current.sta_rate'),
        :row_value => @sta_data[:rate]
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
  end

  def historical_price_indications
    rate_service = RatesService.new(request)
    default_dates = default_dates_hash
    @start_date = ((params[:start_date] || default_dates[:this_year_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:today])).to_date
    @picker_presets = date_picker_presets(@start_date, @end_date)
    
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

    export_format = params[:export_format]
    @report_name = t('reports.pages.price_indications.historical')
    filename_credit_type = (@credit_type.include?('libor') || @credit_type.include?('daily_prime')) ? "arc-#{@credit_type.gsub('_','-')}" : @credit_type
    filename = "historical-price-indications-#{@collateral_type}-#{filename_credit_type}-#{fhlb_report_date_numeric(@start_date)}-to-#{fhlb_report_date_numeric(@end_date)}"
    excel_params = {
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      historical_price_collateral_type: @collateral_type,
      historical_price_credit_type: @credit_type
    }
    if export_format == 'xlsx'
      job_status = RenderReportExcelJob.perform_later(current_member_id, 'historical_price_indications', filename, excel_params).job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
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
    member_balances = MemberBalanceService.new(current_member_id, request)
    column_headings = [t('reports.pages.interest_rate_resets.effective_date'), t('common_table_headings.advance_number'), t('reports.pages.interest_rate_resets.prior_rate'), t('reports.pages.interest_rate_resets.new_rate'), t('reports.pages.interest_rate_resets.next_reset')]
    irr_data = member_balances.interest_rate_resets
    if report_disabled?(INTEREST_RATE_RESETS_WEB_FLAGS)
      rows = []
    else
      raise StandardError, 'There has been an error and ReportsController#interest_rate_resets has encountered nil. Check error logs.' if irr_data.nil?
      @date_processed = irr_data[:date_processed]
      rows = irr_data[:interest_rate_resets].collect do |row|
        columns = []
        row.each do |value|
          if value[0] == 'prior_rate' || value[0] == 'new_rate'
            columns << {type: :index, value: value[1]}
          elsif value[0] == 'effective_date'
            columns << {type: :date, value: value[1]}
          elsif value[0] == 'next_reset' && value[1]
            columns << {type: :date, value: value[1]}
          elsif value[0] == 'next_reset'
            columns << {value: t('global.open')}
          else
            columns << {value: value[1]}
          end
        end
        {columns: columns}
      end
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
    @start_date = (params[:start_date] || last_month_end).to_date
    if report_disabled?(SECURITIES_SERVICES_STATMENT_WEB_FLAGS)
      @statement = {}
    else
      member_balances = MemberBalanceService.new(current_member_id, request)
      @statement = member_balances.securities_services_statement(@start_date)
      raise StandardError, "There has been an error and ReportsController#securities_services_statement has encountered nil. Check error logs." if @statement.nil?
    end
    @picker_presets = date_picker_presets(@start_date)
    @date_picker_filter = DATE_PICKER_FILTERS[:end_of_month]
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
    rows = if letters_of_credit[:credits]
      letters_of_credit[:credits].collect do |credit|
        {
          columns: [
            {value: credit[:lc_number], type: nil},
            {value: credit[:current_par], type: :currency_whole},
            {value: credit[:maintenance_charge], type: :currency_whole},
            {value: credit[:trade_date], type: :date, classes: [:'report-cell-right']},
            {value: credit[:settlement_date], type: :date, classes: [:'report-cell-right']},
            {value: credit[:maturity_date], type: :date, classes: [:'report-cell-right']},
            {value: credit[:description], type: nil}
          ]
        }
      end
    else
      []
    end
    @loc_table_data = {
      column_headings: [t('reports.pages.letters_of_credit.headers.lc_number'), fhlb_add_unit_to_table_header(t('common_table_headings.current_par'), '$'), t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), t('common_table_headings.trade_date'), t('common_table_headings.settlement_date'), t('common_table_headings.maturity_date'), t('common_table_headings.description')],
      rows: rows,
      footer: [{value: t('global.total')}, {value: @total_current_par, type: :currency_whole}, {value: nil, colspan: 5}]
    }
  end

  def most_recent_business_day(d)
    return d - 1.day if d.saturday?
    return d - 2.day if d.sunday?
    d
  end

  def securities_transactions
    @max_date   = most_recent_business_day(Time.zone.now.to_date - 1.day)
    @start_date = params[:start_date] ? [params[:start_date].to_date, @max_date].min : @max_date
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
    column_headings = [t('reports.pages.securities_transactions.custody_account_no'), t('common_table_headings.cusip'), t('reports.pages.securities_transactions.transaction_code'), t('common_table_headings.security_description'), t('reports.pages.securities_transactions.units'), t('reports.pages.securities_transactions.maturity_date'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.payment_or_principal'), '$'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.interest'), '$'), fhlb_add_unit_to_table_header(t('reports.pages.securities_transactions.total'), '$')]
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
    @report_name = t('reports.authorizations.title')
    export_format = params[:export_format]
    @today = Time.zone.today

    if export_format == 'pdf'
      pdf_job_status = RenderReportPDFJob.perform_later(current_member_id, 'authorizations', "authorizations", {authorizations_filter: @authorizations_filter.to_s}).job_status
    end
    unless pdf_job_status.nil?
      pdf_job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(pdf_job_status), job_cancel_url: job_cancel_url(pdf_job_status)}
    else
      @authorizations_dropdown_options = AUTHORIZATIONS_DROPDOWN_MAPPING.collect{|key, value| [value, key]}
      @authorizations_dropdown_options.each do |option|
        if option.last == @authorizations_filter
          @authorizations_filter_text = option.first
          break
        end
      end

      @authorizations_table_data = {
        :column_headings => [t('user_roles.user.title'), @report_name]
      }

      @job_status_url = false
      @load_url = false

      if params[:job_id] || @print_layout
        if @print_layout
          users = MembersService.new(request).signers_and_users(current_member_id) || []
        else
          job_status = JobStatus.find_by(id: params[:job_id], user_id: current_user.id, status: JobStatus.statuses[:completed] )
          raise ActiveRecord::RecordNotFound unless job_status
          users = JSON.parse(job_status.result_as_string).collect! {|o| o.with_indifferent_access}
          job_status.destroy
        end

        users = users.sort_by{|x| x[:display_name]}
        rows = []
        users.each do |user|
          user_roles = roles_for_signers(user)
          if @authorizations_filter == 'user' && user_roles.include?(t('user_roles.user.title'))
            rows << {columns: [{type: nil, value: user[:display_name]}, {type: :list, value: user_roles}]}
          else
            next if user_roles.empty? || (@authorizations_filter != 'all' && !user[:roles].include?(@authorizations_filter))
            rows << {columns: [{type: nil, value: user[:display_name]}, {type: :list, value: user_roles}]}
          end
        end

        @authorizations_table_data[:rows] = rows

        render layout: false if request.xhr?
      else
        job_status = MemberSignersAndUsersJob.perform_later(current_member_id).job_status
        job_status.update_attributes!(user_id: current_user.id)
        @job_status_url = job_status_url(job_status)
        @load_url = reports_authorizations_url(job_id: job_status.id, authorizations_filter: @authorizations_filter)
        @authorizations_table_data[:deferred] = true
      end
    end
  end

  def parallel_shift
    if report_disabled?(PARALLEL_SHIFT_WEB_FLAGS)
      parallel_shift = {putable_advances: {}}
    else
      member_balances = MemberBalanceService.new(current_member_id, request)
      parallel_shift = member_balances.parallel_shift
      raise StandardError, "There has been an error and ReportsController#parallel_shift has encountered nil. Check error logs." if parallel_shift.nil?
    end
    @as_of_date = parallel_shift[:as_of_date]
    rows = []
    parallel_shift[:putable_advances].each do |advance|
      rows << {
        columns:[
          {type: nil, value: advance[:advance_number]},
          {type: :date, value: advance[:issue_date]},
          {type: :rate, value: advance[:interest_rate] * 100},
          {type: (advance[:shift_neg_300].blank? ? nil : :rate), value: advance[:shift_neg_300] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_neg_200].blank? ? nil : :rate), value: advance[:shift_neg_200] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_neg_100].blank? ? nil : :rate), value: advance[:shift_neg_100] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_0].blank? ? nil : :rate), value: advance[:shift_0] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_100].blank? ? nil : :rate), value: advance[:shift_100] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_200].blank? ? nil : :rate), value: advance[:shift_200] || t('global.na'), classes: [:'report-cell-left']},
          {type: (advance[:shift_300].blank? ? nil : :rate), value: advance[:shift_300] || t('global.na'), classes: [:'report-cell-left']}
        ]
      }
    end
    @parallel_shift_table_data = {
      column_headings: [t('common_table_headings.advance_number'), t('global.issue_date'), fhlb_add_unit_to_table_header(t('common_table_headings.interest_rate'), '%'), [-300,-200,-100,0,100,200,300].collect{|x| fhlb_formatted_number(x)}].flatten,
      rows: rows
    }
  end

  def current_securities_position
    @securities_filter = params['securities_filter'] || 'all'
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(CURRENT_SECURITIES_POSITION_WEB_FLAG)
      @current_securities_position = {securities:[]}
    else
      @current_securities_position = member_balances.current_securities_position(@securities_filter)
      raise StandardError, "There has been an error and ReportsController#current_securities_position has encountered nil. Check error logs." if @current_securities_position.nil?
    end
    securities_instance_variables(@current_securities_position, @securities_filter)
  end

  def monthly_securities_position
    @securities_filter = params['securities_filter'] || 'all'
    @month_end_date = (params[:start_date] || last_month_end).to_date
    @date_picker_filter = DATE_PICKER_FILTERS[:end_of_month]
    @picker_presets = date_picker_presets(@month_end_date)
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(MONTHLY_SECURITIES_WEB_FLAGS)
      @monthly_securities_position = {securities:[]}
    else
      @monthly_securities_position = member_balances.monthly_securities_position(@month_end_date, @securities_filter)
      raise StandardError, "There has been an error and ReportsController#monthly_securities_position has encountered nil. Check error logs." if @monthly_securities_position.nil?
    end
    securities_instance_variables(@monthly_securities_position, @securities_filter)
  end

  def forward_commitments
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(FORWARD_COMMITMENTS_WEB_FLAG)
      forward_commitments = {}
    else
      forward_commitments = member_balances.forward_commitments
      raise StandardError, "There has been an error and ReportsController#monthly_securities_position has encountered nil. Check error logs." if forward_commitments.nil?
    end

    rows = if forward_commitments[:advances]
      forward_commitments[:advances].collect do |advance|
        if advance[:interest_rate].nil? || advance[:interest_rate].to_f == 0
          interest_rate = t('global.tbd')
          interest_rate_type = nil
        else
          interest_rate = advance[:interest_rate]
          interest_rate_type = :rate
        end
        {
          columns: [
            {value: advance[:trade_date], type: :date, classes: [:'report-cell-right']},
            {value: advance[:funding_date], type: :date, classes: [:'report-cell-right']},
            {value: advance[:maturity_date], type: :date, classes: [:'report-cell-right']},
            {value: advance[:advance_number], type: nil},
            {value: advance[:advance_type], type: nil},
            {value: advance[:current_par], type: :currency_whole, classes: [:'report-cell-right']},
            {value: interest_rate, type: interest_rate_type, classes: [:'report-cell-right']}
          ]
        }
      end
    else
      []
    end

    @as_of_date = forward_commitments[:as_of_date]
    @total_current_par = forward_commitments[:total_current_par]
    @table_data = {
      column_headings: [t('common_table_headings.trade_date'), t('common_table_headings.funding_date'), t('common_table_headings.maturity_date'), t('common_table_headings.advance_number'), t('common_table_headings.advance_type'), fhlb_add_unit_to_table_header(t('common_table_headings.current_par'), '$'), fhlb_add_unit_to_table_header(t('common_table_headings.interest_rate'), '%')].collect{|x| {title: x, sortable: true}},
      rows: rows,
      footer: [{ value: t('global.total'), colspan: 5}, {value: @total_current_par, type: :currency_whole, classes: [:'report-cell-right']}, {value: ''}]
    }
  end

  def capital_stock_and_leverage
    member_balances = MemberBalanceService.new(current_member_id, request)
    if report_disabled?(CAPITAL_STOCK_AND_LEVERAGE_WEB_FLAGS)
      cap_stock_and_leverage = {}
    else
      cap_stock_and_leverage = member_balances.capital_stock_and_leverage
      raise StandardError, "There has been an error and ReportsController#capital_stock_and_leverage has encountered nil. Check error logs." if cap_stock_and_leverage.nil?
    end

    position_table_headings = [t('reports.pages.capital_stock_and_leverage.stock_owned'), t('reports.pages.capital_stock_and_leverage.minimum_requirement'), t('reports.pages.capital_stock_and_leverage.excess_stock'), t('reports.pages.capital_stock_and_leverage.surplus_stock')]
    leverage_table_headings = [t('reports.pages.capital_stock_and_leverage.stock_owned'), t('reports.pages.capital_stock_and_leverage.activity_based_requirement'), t('reports.pages.capital_stock_and_leverage.remaining_stock_html').html_safe, t('reports.pages.capital_stock_and_leverage.remaining_leverage')]

    @position_table_data = {
      column_headings: position_table_headings.collect{|heading| fhlb_add_unit_to_table_header(heading, '$')},
      rows: [
        {
          columns: [
            {value: cap_stock_and_leverage[:stock_owned], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:minimum_requirement], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:excess_stock], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:surplus_stock], type: :number, classes: [:'report-cell-right']}
          ]
        }
      ]
    }

    @leverage_table_data = {
      column_headings: leverage_table_headings.collect{|heading| fhlb_add_unit_to_table_header(heading, '$')},
      rows: [
        {
          columns: [
            {value: cap_stock_and_leverage[:stock_owned], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:activity_based_requirement], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:remaining_stock], type: :number, classes: [:'report-cell-right']},
            {value: cap_stock_and_leverage[:remaining_leverage], type: :number, classes: [:'report-cell-right']}
          ]
        }
      ]
    }
  end

  def account_summary

    @date = params[:end_date] || Time.zone.now.to_date
    export_format = params[:export_format]
    @report_name = t('reports.account_summary.title')

    if export_format == 'pdf'
      job_status = RenderReportPDFJob.perform_later(current_member_id, 'account_summary', 'account-summary', {end_date: @date.to_s}).job_status
    end
    unless job_status.nil?
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
      if report_disabled?(ACCOUNT_SUMMARY_WEB_FLAGS)
        raise 'Report Disabled'
      end

      member_balance_service = MemberBalanceService.new(current_member_id, request)
      member_profile = member_balance_service.profile
      if !member_profile
        member_profile = {
          credit_outstanding: {},
          collateral_borrowing_capacity: {
            standard: {
            },
            sbc: {
            }
          },
          capital_stock: {}
        }
      end

      members_service = MembersService.new(request)
      member_details = members_service.member(current_member_id) || {}

      @intraday_datetime = Time.zone.now
      @credit_datetime = Time.zone.now
      @collateral_notice = member_profile[:collateral_delivery_status] == 'Y'
      @sta_number = member_details[:sta_number]
      @fhfb_number = member_details[:fhfb_number]
      @member_name = member_details[:name]
      @financing_availability = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.asset_percentage')},
              {value: (member_profile[:financing_percentage] * 100 if member_profile[:financing_percentage]), type: :percentage}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.maximum_term')},
              {value: member_profile[:maximum_term], type: :months}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.total_assets')},
              {value: member_profile[:total_assets], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.total_financing_availability')},
              {value: member_profile[:total_financing_available], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.approved_credit')},
              {value: member_profile[:approved_long_term_credit], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.credit_outstanding')},
              {value: member_profile[:credit_outstanding][:total], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.financing_availability.forward_commitments')},
              {value: member_profile[:forward_commitments], type: :currency_whole}
            ]
          }
        ],
        footer: [
          {value: t('reports.account_summary.financing_availability.remaining_financing_availability')},
          {value: member_profile[:remaining_financing_available], type: :currency_whole}
        ]
      }

      if member_profile[:mpf_credit_available].present? && member_profile[:mpf_credit_available] > 0
        @financing_availability[:rows].insert(-2, {
                                                  columns: [
                                                    {value: t('reports.account_summary.financing_availability.mpf_credit_available')},
                                                    {value: member_profile[:mpf_credit_available], type: :currency_whole}
                                                  ]
                                                })
      end

      @credit_outstanding = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.standard_advances')},
              {value: member_profile[:credit_outstanding][:standard], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.sbc_advances')},
              {value: member_profile[:credit_outstanding][:sbc], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.swaps_credit')},
              {value: member_profile[:credit_outstanding][:swaps_credit], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.swaps_notational')},
              {value: member_profile[:credit_outstanding][:swaps_notational], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.investments')},
              {value: member_profile[:credit_outstanding][:investments], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.credit_outstanding.letters_of_credit')},
              {value: member_profile[:credit_outstanding][:letters_of_credit], type: :currency_whole}
            ]
          }
        ],
        footer: [
          {value: t('reports.account_summary.credit_outstanding.title')},
          {value: member_profile[:credit_outstanding][:total], type: :currency_whole}
        ]
      }

      if member_profile[:credit_outstanding][:mpf_credit].present? && member_profile[:credit_outstanding][:mpf_credit] > 0
        @credit_outstanding[:rows] << {
          columns: [
            {value: t('reports.account_summary.credit_outstanding.mpf_credit')},
            {value: member_profile[:credit_outstanding][:mpf_credit], type: :currency_whole}
          ]
        }
      end

      @standard_collateral = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.standard.total')},
              {value: member_profile[:collateral_borrowing_capacity][:standard][:total], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.standard.remaining')},
              {value: member_profile[:collateral_borrowing_capacity][:standard][:remaining], type: :currency_whole}
            ]
          }
        ]
      }

      @sbc_collateral = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.sbc.total_market')},
              {value: member_profile[:collateral_borrowing_capacity][:sbc][:total_market], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.sbc.remaining_market')},
              {value: member_profile[:collateral_borrowing_capacity][:sbc][:remaining_market], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.sbc.total')},
              {value: member_profile[:collateral_borrowing_capacity][:sbc][:total_borrowing], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.sbc.remaining')},
              {value: member_profile[:collateral_borrowing_capacity][:sbc][:remaining_borrowing], type: :currency_whole}
            ]
          }
        ]
      }

      @collateral_totals = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.totals.total')},
              {value: member_profile[:collateral_borrowing_capacity][:total], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.collateral_borrowing_capacity.totals.remaining')},
              {value: member_profile[:collateral_borrowing_capacity][:remaining], type: :currency_whole}
            ]
          }
        ]
      }

      @capital_stock_and_leverage = {
        rows: [
          {
            columns: [
              {value: t('reports.account_summary.capital_stock.stock_owned')},
              {value: member_profile[:capital_stock][:stock_owned], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.capital_stock.stock_requirement')},
              {value: member_profile[:capital_stock][:activity_based_requirement], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.capital_stock.excess_stock')},
              {value: member_profile[:capital_stock][:remaining_stock], type: :currency_whole}
            ]
          },
          {
            columns: [
              {value: t('reports.account_summary.capital_stock.leverage')},
              {value: member_profile[:capital_stock][:remaining_leverage], type: :currency_whole}
            ]
          }
        ]
      }
    end
  end

  private
  def securities_instance_variables(securities_position, filter)
    as_of_date = securities_position[:as_of_date]
    @headings = {
      total_original_par: t("reports.pages.securities_position.#{filter}_securities.total_original_par_heading", date: fhlb_date_long_alpha(as_of_date)),
      total_current_par: t("reports.pages.securities_position.#{filter}_securities.total_current_par_heading", date: fhlb_date_long_alpha(as_of_date)),
      total_market_value: t("reports.pages.securities_position.#{filter}_securities.total_market_value_heading", date: fhlb_date_long_alpha(as_of_date)),
      table_heading: t("reports.pages.securities_position.#{filter}_securities.table_heading", n: securities_position[:securities].length, date: fhlb_date_long_alpha(as_of_date)),
      footer_total: t("reports.pages.securities_position.#{filter}_securities.total")
    }
    @securities_filter_options = [
      [t('reports.pages.securities_position.filter.all'), 'all'],
      [t('reports.pages.securities_position.filter.pledged'), 'pledged'],
      [t('reports.pages.securities_position.filter.unpledged'), 'unpledged']
    ]
    @securities_filter_options.each do |option|
      if option[1] == @securities_filter
        @securities_filter_text = option[0]
        break
      end
    end
  end

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
    roles = signer[:roles].collect do |role|
      AUTHORIZATIONS_MAPPING[role]
    end
    roles.compact!
    roles.present? ? roles : [t('user_roles.user.title')]
  end

  def last_month_end
    today = Time.zone.today
    today == today.end_of_month ? today.end_of_month : (today - 1.month).end_of_month
  end

end