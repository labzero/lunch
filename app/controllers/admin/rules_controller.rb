class Admin::RulesController < Admin::BaseController
  include CustomFormattingHelper

  VALID_TERMS = [
    :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'9month', :'12month', :'1year',
    :'2year', :'3year'
  ].freeze

  LONG_FRC_TERMS = [:'1year', :'2year', :'3year']

  before_action do
    set_active_nav(:rules)
    @can_edit_trade_rules = policy(:web_admin).edit_trade_rules?
  end

  before_action only: [:update_limits, :update_rate_bands, :update_advance_availability_by_term] do
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
    etransact_service = EtransactAdvancesService.new(request)
    term_limit_data = etransact_service.limits
    raise 'There has been an error and Admin::RulesController#advance_availability_by_term has encountered nil. Check error logs.' if term_limit_data.nil?
    @availability_headings = {
      column_headings: ['', t('dashboard.quick_advance.table.axes_labels.standard'), t('dashboard.quick_advance.table.axes_labels.securities_backed'), '', ''],
      rows: [{
        columns: [
          {value: nil},
          {value: t('dashboard.quick_advance.table.whole_loan')},
          {value: t('dashboard.quick_advance.table.agency')},
          {value: t('dashboard.quick_advance.table.aaa')},
          {value: t('dashboard.quick_advance.table.aa')}
        ]
      }]
    }
    @vrc_availability = {rows: []}
    @frc_availability = {rows: []}
    @long_term_availability = {rows: []}
    term_limit_data.each do |bucket|
      term = bucket[:term].to_sym
      raise "There has been an error and Admin::RulesController#advance_availability_by_term has encountered an etransact_service.limits bucket with an invalid term: #{term}" unless VALID_TERMS.include?(term)
      term_label = term == :open ? t('admin.advance_availability.availability_by_term.open_label') : t("admin.term_rules.daily_limit.dates.#{term}")
      row = {columns: [
        {value: term_label},
        {
          name: "term_limits[#{term}][whole_loan_enabled]",
          type: :checkbox,
          submit_unchecked_boxes: true,
          checked: bucket[:whole_loan_enabled],
          label: true,
          disabled: !@can_edit_trade_rules
        },
        {
          name: "term_limits[#{term}][sbc_agency_enabled]",
          type: :checkbox,
          submit_unchecked_boxes: true,
          checked: bucket[:sbc_agency_enabled],
          label: true,
          disabled: !@can_edit_trade_rules
        },
        {
          name: "term_limits[#{term}][sbc_aaa_enabled]",
          type: :checkbox,
          submit_unchecked_boxes: true,
          checked: bucket[:sbc_aaa_enabled],
          label: true,
          disabled: !@can_edit_trade_rules
        },
        {
          name: "term_limits[#{term}][sbc_aa_enabled]",
          type: :checkbox,
          submit_unchecked_boxes: true,
          checked: bucket[:sbc_aa_enabled],
          label: true,
          disabled: !@can_edit_trade_rules
        }
      ]}
      if term == :open
        @vrc_availability[:rows] << row
      elsif LONG_FRC_TERMS.include?(term)
        @long_term_availability[:rows] << row
      else
        @frc_availability[:rows] << row
      end
    end
  end

  # PUT
  def update_advance_availability_by_term
    etransact_service = EtransactAdvancesService.new(request)
    term_limits = params[:term_limits].with_indifferent_access
    term_limits.each do |term, limit_data|
      limit_data.each do |type, status|
        term_limits[term][type] = status == 'on'
      end
    end
    term_limits_results = etransact_service.update_term_limits(term_limits)
    raise "There has been an error and Admin::RulesController#update_advance_availability_by_term has encountered nil" unless term_limits_results
    set_flash_message(term_limits_results)
    redirect_to action: :advance_availability_by_term
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

  # GET
  def rate_report
    rate_summary = RatesService.new(request).quick_advance_rates(:admin)
    raise 'There has been an error and Admin::RulesController#rate_report has encountered nil' unless rate_summary
    rate_summary = process_rate_summary(rate_summary)
    column_headings = ['', '',
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.opening_rate'), '%'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.current_rate'), '%'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.change'), 'bps'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.low_off').html_safe, '%'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.low_warn').html_safe, '%'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.high_warn').html_safe, '%'),
      fhlb_add_unit_to_table_header(t('admin.term_rules.rate_report.high_off').html_safe, '%')]
    @vrc_rate_report = {
      column_headings: column_headings,
      rows: []
    }
    @frc_rate_report = {
      column_headings: column_headings,
      rows: []
    }
    rate_summary.each do |advance_term, advance_types|
      next if advance_term == 'overnight'
      advance_types.each do |type, rate_info|
        open = advance_term == 'open'
        term_label = open ? t('admin.term_rules.daily_limit.dates.open') : t("dashboard.quick_advance.table.axes_labels.#{advance_term}")
        row = {columns: [
          {value: nil}, #TODO - This will become the column that indicates if a threshold has been breached as part of MEM-2317
          {value:  term_label + ': ' + t("dashboard.quick_advance.table.#{type}")},
          {value: rate_info[:start_of_day_rate].to_f, type: :rate},
          {value: rate_info[:rate].to_f, type: :rate},
          {value: rate_info[:rate_change_bps], type: :basis_point},
          {value: rate_info[:rate_band_info][:low_band_off_rate].to_f, type: :rate},
          {value: rate_info[:rate_band_info][:low_band_warn_rate].to_f, type: :rate},
          {value: rate_info[:rate_band_info][:high_band_warn_rate].to_f, type: :rate},
          {value: rate_info[:rate_band_info][:high_band_off_rate].to_f, type: :rate}
        ]}
        open ? @vrc_rate_report[:rows] << row : @frc_rate_report[:rows] << row
      end
    end
  end

  # GET
  def term_details
    term_details_data = EtransactAdvancesService.new(request).limits
    raise 'There has been an error and EtransactAdvancesService#limits has encountered nil. Check error logs.' if term_details_data.nil?
    @term_details = {
      column_headings: ['', t('admin.term_rules.term_details.low_days_to_maturity'), t('admin.term_rules.term_details.high_days_to_maturity')]
    }
    @term_details[:rows] = term_details_data.collect do |bucket|
      term = bucket[:term]
      raise "There has been an error and Admin::RulesController#term_details has encountered an etransact_service.limits bucket with an invalid term: #{term}" unless VALID_TERMS.include?(term.to_sym)
      {columns: [
        {value: t("admin.term_rules.daily_limit.dates.#{term}")},
        {value: bucket[:low_days_to_maturity].to_i,
         type: :number
        },
        {value: bucket[:high_days_to_maturity].to_i,
         type: :number
        }
      ]}
    end
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

  def process_rate_summary(rate_summary)
    processed_summary = {}
    rate_summary.each do |advance_type, advance_terms|
      next if advance_type == 'timestamp'
      advance_terms.each do |term, rate_info|
        processed_summary[term] ||= {}
        processed_summary[term][advance_type] = rate_info.with_indifferent_access
      end
    end
    processed_summary
  end
end