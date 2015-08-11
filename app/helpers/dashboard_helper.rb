module DashboardHelper
  TOOLTIP='dashboard.quick_advance.tooltip'
  TABLE='dashboard.quick_advance.table'
  
  def make_quick_advance_tooltip_data(rate_data)
    interest_day_count = rate_data[:interest_day_count].to_s.gsub('/', '')
    date               = rate_data[:maturity_date].to_date
    date_formatted     = fhlb_date_standard_numeric(date)
    payment_label      = t("#{TOOLTIP}.payment_on")
    day_label          = t("#{TOOLTIP}.interest_day_count")
    maturity_label     = t("#{TOOLTIP}.maturity_date")
    day                = t("#{TABLE}.#{interest_day_count}")
    {
      payment_label  => rate_data[:payment_on], 
      day_label      => day,
      maturity_label => date_formatted
    }
  end
end