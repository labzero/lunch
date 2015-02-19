class ReportsController < ApplicationController
  include DatePickerHelper
  include CustomFormattingHelper
  include ActionView::Helpers::NumberHelper

  MEMBER_ID = 750 #this is the hard-coded fhlb client id number we're using for the time-being


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
          route: reports_advances_detail_path
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
    member_balances = MemberBalanceService.new(MEMBER_ID, request)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    @capital_stock_activity = member_balances.capital_stock_activity(@start_date, @end_date)
    raise StandardError, "There has been an error and ReportsController#capital_stock_activity has returned nil. Check error logs." if @capital_stock_activity.blank?
    @picker_presets = range_picker_default_presets(@start_date, @end_date)
  end

  def borrowing_capacity
    member_balances = MemberBalanceService.new(MEMBER_ID, request)
    date = params[:end_date] || Time.zone.now.to_date
    @borrowing_capacity_summary = member_balances.borrowing_capacity_summary(date.to_date)
    raise StandardError, "There has been an error and ReportsController#borrowing_capacity has returned nil. Check error logs." if @borrowing_capacity_summary.blank?
  end

  def settlement_transaction_account
    default_dates = default_dates_hash
    member_balances = MemberBalanceService.new(MEMBER_ID, request)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    @daily_balance_key = MemberBalanceService::DAILY_BALANCE_KEY
    @picker_presets = range_picker_default_presets(@start_date, @end_date)
    @filter_options = [
        [t('global.all'), 'all'],
        [t('global.debits'), 'debit'],
        [t('global.credits'), 'credit']
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
    @settlement_transaction_account = member_balances.settlement_transaction_account(@start_date, @end_date, @filter)
    raise StandardError, "There has been an error and ReportsController#settlement_transaction_account has returned nil. Check error logs." if @settlement_transaction_account.blank?
    @show_ending_balance = false
    if @settlement_transaction_account[:activities] && @settlement_transaction_account[:activities].length > 0
      @show_ending_balance = @end_date != @settlement_transaction_account[:activities][0][:trans_date].to_date || @settlement_transaction_account[:activities][0][:balance].blank?
    end
  end

  def advances_detail
    @as_of_date = (params[:as_of_date] || Time.zone.now.to_date).to_date
    member_balances = MemberBalanceService.new(MEMBER_ID, request)
    @advances_detail = member_balances.advances_details(@as_of_date)
    raise StandardError, "There has been an error and ReportsController#advances_detail has returned nil. Check error logs." if @advances_detail.blank?
    @picker_presets = range_picker_default_presets(@as_of_date)
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
        @advances_detail[:advances_details][i][:prepayment_fee_indication] = number_to_currency(advance[:prepayment_fee_indication]) || t('global.not_applicable')
      end
    end
  end

  def historical_price_indications
    rate_service = RatesService.new(request)
    default_dates = default_dates_hash
    @start_date = ((params[:start_date] || default_dates[:this_year_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:today])).to_date

    @picker_presets = range_picker_default_presets(@start_date, @end_date)
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
        [t('reports.pages.price_indications.fixed_rate_credit'), 'frc'],
        [t('reports.pages.price_indications.variable_rate_credit'), 'vrc'],
        [t('reports.pages.price_indications.adjustable_rate.1m_libor'), '1m_libor'],
        [t('reports.pages.price_indications.adjustable_rate.3m_libor'), '3m_libor'],
        [t('reports.pages.price_indications.adjustable_rate.6m_libor'), '6m_libor'],
        [t('reports.pages.price_indications.adjustable_rate.daily_prime'), 'daily_prime'],
        [t('reports.pages.price_indications.adjustable_rate.embedded_cap'), 'embedded_cap']
    ]
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

    @historical_price_indications = rate_service.historical_price_indications(@start_date, @end_date, @collateral_type, @credit_type)
    raise StandardError, "There has been an error and ReportsController#historical_price_indications has returned nil. Check error logs." if @historical_price_indications.blank?
  end

end