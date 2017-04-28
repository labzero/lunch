class Admin::RulesController < Admin::BaseController
  include CustomFormattingHelper

  VALID_TERMS = [
    :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'9month', :'12month', :'1year',
    :'2year', :'3year'
  ].freeze

  before_action do
    set_active_nav(:rules)
    @can_edit_trade_rules = policy(:web_admin).edit_trade_rules?
  end

  before_action only: [:update_limits, :update_rate_bands] do
    authorize :web_admin, :edit_trade_rules?
  end

  # GET
  def limits
    etransact_service = EtransactAdvancesService.new(request)
    global_limit_data = etransact_service.settings
    term_limit_data = etransact_service.limits
    raise 'There has been an error and Admin::RulesController#limits has encountered nil. Check error logs.' if global_limit_data.nil? || term_limit_data.nil?
    @global_limits = {}
    @global_limits[:rows] = [
      {columns: [
        {value: fhlb_add_unit_to_table_header(t('admin.term_rules.daily_limit.per_member'), '$')},
        {value: global_limit_data[:shareholder_total_daily_limit],
         type: :text_field,
         name: 'global_limits[shareholder_total_daily_limit]',
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        }
      ]},
      {columns: [
        {value: fhlb_add_unit_to_table_header(t('admin.term_rules.daily_limit.all_member'), '$')},
        {value: global_limit_data[:shareholder_web_daily_limit],
         type: :text_field,
         name: 'global_limits[shareholder_web_daily_limit]',
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        }
      ]}
    ]
    @term_limits = {
      column_headings: ['', fhlb_add_unit_to_table_header(t('admin.term_rules.daily_limit.minimum_online'), '$'), fhlb_add_unit_to_table_header(t('admin.term_rules.daily_limit.daily'), '$')]
    }
    @term_limits[:rows] = term_limit_data.collect do |bucket|
      term = bucket[:term]
      raise "There has been an error and Admin::RulesController#limits has encountered an etransact_service.limits bucket with an invalid term: #{term}" unless VALID_TERMS.include?(term.to_sym)
      {columns: [
        {value: t("admin.term_rules.daily_limit.dates.#{term}")},
        {value: bucket[:min_online_advance].to_i,
         type: :text_field,
         name: "term_limits[#{term}][min_online_advance]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        },
        {value: bucket[:term_daily_limit].to_i,
         type: :text_field,
         name: "term_limits[#{term}][term_daily_limit]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        }
      ]}
    end
  end

  # PUT
  def update_limits
    etransact_service = EtransactAdvancesService.new(request)
    global_limits = params[:global_limits].with_indifferent_access
    term_limits = params[:term_limits].with_indifferent_access
    settings_results = etransact_service.update_settings(global_limits)
    term_limits_results = etransact_service.update_term_limits(term_limits)
    raise "There has been an error and Admin::RulesController#update_limits has encountered nil" unless settings_results && term_limits_results
    set_flash_message([settings_results, term_limits_results])
    redirect_to action: :limits
  end

  # GET
  def advance_availability_status

  end

  # GET
  def advance_availability_by_term

  end

  # GET
  def advance_availability_by_member
    quick_advance_enabled = MembersService.new(request).quick_advance_enabled
    raise "There has been an error and Admin::RulesController#advance_availability_by_member has encountered nil" unless quick_advance_enabled.present?
    @advance_availability_table = {
      rows: quick_advance_enabled.collect do |flag|
        {
          columns: [
            { value: flag['member_name'] },
            { name: 'quick_advance_enabled',
              value:  flag['fhlb_id'],
              checked: flag['quick_advance_enabled'],
              type: :checkbox,
              disabled: true }
          ]
        }
      end
    }
  end

  # GET
  def rate_bands
    rate_bands = RatesService.new(request).rate_bands
    raise 'There has been an error and Admin::RulesController#rate_bands has encountered nil' unless rate_bands
    @rate_bands = {
      column_headings: ['', t('admin.term_rules.rate_bands.low_shutdown_html').html_safe, t('admin.term_rules.rate_bands.low_warning_html').html_safe,
                        t('admin.term_rules.rate_bands.high_warning_html').html_safe, t('admin.term_rules.rate_bands.high_shutdown_html').html_safe],
      rows: []
    }
    rate_bands.each do |term, rate_band_info|
      next if term == 'overnight'
      raise "There has been an error and Admin::RulesController#rate_bands has encountered a RatesService.rate_bands bucket with an invalid term: #{term}" unless VALID_TERMS.include?(term.to_sym)
      row = {columns: [
        {value: term == 'open' ? t('admin.term_rules.daily_limit.dates.open') : t("dashboard.quick_advance.table.axes_labels.#{term}")},
        {value: rate_band_info['LOW_BAND_OFF_BP'].to_i,
         type: :text_field,
         name: "rate_bands[#{term}][LOW_BAND_OFF_BP]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        },
        {value: rate_band_info['LOW_BAND_WARN_BP'].to_i,
         type: :text_field,
         name: "rate_bands[#{term}][LOW_BAND_WARN_BP]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        },
        {value: rate_band_info['HIGH_BAND_WARN_BP'].to_i,
         type: :text_field,
         name: "rate_bands[#{term}][HIGH_BAND_WARN_BP]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        },
        {value: rate_band_info['HIGH_BAND_OFF_BP'].to_i,
         type: :text_field,
         name: "rate_bands[#{term}][HIGH_BAND_OFF_BP]",
         value_type: :number,
         disabled: !@can_edit_trade_rules,
         options: {html: false}
        }
      ]}
      @rate_bands[:rows] << row
    end
  end

  # PUT
  def update_rate_bands
    rate_bands = params[:rate_bands].with_indifferent_access
    rate_bands_result = RatesService.new(request).update_rate_bands(rate_bands)
    raise "There has been an error and Admin::RulesController#update_rate_bands has encountered nil" unless rate_bands_result
    set_flash_message(rate_bands_result)
    redirect_to action: :rate_bands
  end

  private

  def set_flash_message(results)
    errors = Array.wrap(results).collect{ |result| result[:error] }.compact
    if errors.present?
      flash[:error] = t('admin.term_rules.messages.error')
    else
      flash[:notice] = t('admin.term_rules.messages.success')
    end
  end
end