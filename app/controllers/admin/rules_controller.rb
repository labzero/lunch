class Admin::RulesController < Admin::BaseController
  include CustomFormattingHelper

  VALID_TERMS = [
    :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'9month', :'12month', :'1year',
    :'2year', :'3year'
  ].freeze

  before_action do
    set_active_nav(:rules)
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
        {value: global_limit_data[:shareholder_total_daily_limit], type: :number}
      ]},
      {columns: [
        {value: fhlb_add_unit_to_table_header(t('admin.term_rules.daily_limit.all_member'), '$')},
        {value: global_limit_data[:shareholder_web_daily_limit], type: :number}
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
        {value: bucket[:min_online_advance].to_i, type: :number},
        {value: bucket[:term_daily_limit].to_i, type: :number}
      ]}
    end
  end
end