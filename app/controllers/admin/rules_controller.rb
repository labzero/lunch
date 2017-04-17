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

  before_action only: [:update_limits] do
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
    if settings_results[:error] || term_limits_results[:error]
      flash[:error] = t('admin.term_rules.messages.error')
    else
      flash[:notice] = t('admin.term_rules.messages.success')
    end
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

  end
end