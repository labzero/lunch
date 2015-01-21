module ControllerHelper
  include ApplicationHelper

  THIS_MONTH_START = Date.today.beginning_of_month
  THIS_MONTH_END = Date.today
  LAST_MONTH_START = THIS_MONTH_START - 1.month
  LAST_MONTH_END = LAST_MONTH_START.end_of_month

  def range_picker_default_presets(custom_start_date, custom_end_date)
    picker_presets = [
        {
            label: t('datepicker.range.this_month', month: THIS_MONTH_START.strftime('%B')),
            start_date: THIS_MONTH_START,
            end_date: THIS_MONTH_END
        },
        {
            label: LAST_MONTH_START.strftime('%B'),
            start_date: LAST_MONTH_START,
            end_date: LAST_MONTH_END
        },
        {
            label: t('datepicker.range.custom'),
            start_date: custom_start_date,
            end_date: custom_end_date,
            is_custom: true
        }
    ]
    picker_presets.each do |preset|
      if preset[:start_date] == custom_start_date && preset[:end_date] == custom_end_date
        preset[:is_default] = true
        break
      end
    end
    picker_presets
  end

end
