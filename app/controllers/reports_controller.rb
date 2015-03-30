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
          available_history: t('reports.history.months12')
        },
        letters_of_credit: {
          updated: t('global.daily'),
          available_history: t('global.all')
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
        trial_balance: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        activity: {
          updated: t('global.daily'),
          available_history: t('reports.history.months12'),
          route: reports_capital_stock_activity_path
        },
        dividend_transaction: {
          updated: t('global.quarterly'),
          available_history: t('reports.history.months36')
        },
        dividend_statement: {
          updated: t('global.quarterly'),
          available_history: t('reports.history.present2007')
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
          available_history: t('global.all')
        },
        cash_projections: {
          updated: t('global.daily'),
          available_history: t('global.current_day')
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
          available_history: t('reports.history.months18')
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
      raise StandardError, "There has been an error and ReportsController#capital_stock_activity has returned nil. Check error logs." if @capital_stock_activity.blank?
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
      raise StandardError, "There has been an error and ReportsController#borrowing_capacity has returned nil. Check error logs." if @borrowing_capacity_summary.blank?
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
      raise StandardError, "There has been an error and ReportsController#settlement_transaction_account has returned nil. Check error logs." if @settlement_transaction_account.blank?
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
    raise StandardError, "There has been an error and ReportsController#advances_detail has returned nil. Check error logs." if @advances_detail.blank?
    @picker_presets = date_picker_presets(@start_date)
    if report_disabled?(ADVANCES_DETAIL_WEB_FLAGS)
      @advances_detail = {}
    else
      @advances_detail = member_balances.advances_details(@start_date)
      raise StandardError, "There has been an error and ReportsController#advances_detail has returned nil. Check error logs." if @advances_detail.blank?
      # prepayment fee indication for detail view
      @advances_detail[:advances_details].each_with_index do |advance, i|
        case advance[:notes]
          when 'unavailable_online'
            @advances_detail[:advances_details][i][:prepayment_fee_indication] = t('reports.pages.advances_detail.unavailable_online')
          when 'not_applicable_to_vrc'
            @advances_detail[:advances_details][i][:prepayment_fee_indication] = t('reports.pages.advances_detail.not_applicable_to_vrc')
          when 'prepayment_fee_restructure'
            @advances_detail[:advances_details][i][:prepayment_fee_indication] = t('reports.pages.advances_detail.prepayment_fee_restructure_html', fee: number_to_currency(advance[:prepayment_fee_indication]), date: fhlb_date_standard_numeric(advance[:structure_product_prepay_valuation_date].to_date))
          else
            @advances_detail[:advances_details][i][:prepayment_fee_indication] = fhlb_formatted_currency(advance[:prepayment_fee_indication], optional_number: true) || t('reports.pages.advances_detail.unavailable_for_past_dates')
        end
      end
    end
    @advances_detail[:advances_details].sort! { |a, b| a[:trade_date] <=> b[:trade_date] } if @advances_detail[:advances_details]
    respond_to do |format|
      format.html { render 'advances_detail' } # you must call render explicitly if you are using respond_to and want PDF generation to work
      format.pdf { send_data RenderReportPDFJob.new.perform(current_member_id, 'advances_detail', {start_date: @start_date}), filename: 'advances.pdf' }
    end
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
      raise StandardError, "There has been an error and ReportsController#historical_price_indications has returned nil. Check error logs." if @historical_price_indications.blank?
    end

    case @credit_type.to_sym
    when :frc
      column_heading_keys = RatesService::HISTORICAL_FRC_TERM_MAPPINGS.values
    when :vrc
      column_heading_keys = RatesService::HISTORICAL_VRC_TERM_MAPPINGS.values
    when :'1m_libor', :'3m_libor', :'6m_libor'
      table_heading = I18n.t("reports.pages.price_indications.#{@credit_type}.table_heading")
      column_heading_keys = RatesService::HISTORICAL_ARC_TERM_MAPPINGS.values
      # TODO add statement for 'embedded_cap' when it is rigged up
    when :daily_prime
      column_heading_keys = RatesService::HISTORICAL_ARC_TERM_MAPPINGS.values
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

  private
  def report_disabled?(report_flags)
    member_info = MembersService.new(request)
    member_info.report_disabled?(current_member_id, report_flags)
  end

end