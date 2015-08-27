module DashboardHelper
  TOOLTIP='dashboard.quick_advance.tooltip'
  
  def make_quick_advance_tooltip_data(rate_data)
    date               = rate_data[:maturity_date].to_date
    date_formatted     = fhlb_date_standard_numeric(date)
    maturity_label     = t("#{TOOLTIP}.maturity_date")
    {
      maturity_label => date_formatted
    }
  end
end