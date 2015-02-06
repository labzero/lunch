module DatePickerHelper

  def default_dates_hash
    today = Date.today
    {
        this_month_start: today.beginning_of_month,
        today: today,
        last_month_start: today.beginning_of_month - 1.month,
        last_month_end: (today.beginning_of_month - 1.month).end_of_month
    }
  end

  def range_picker_default_presets(custom_start_date, custom_end_date, single_date_picker=false)
    default_dates = default_dates_hash
    picker_presets = if single_date_picker
                       [
                           {
                               label: "#{t('global.as_of')} #{t('global.today')}",
                               start_date: default_dates[:today],
                               end_date: default_dates[:today]
                           },
                           {
                               label: "#{t('global.as_of')} #{default_dates[:last_month_end].to_date.strftime('%B')} #{default_dates[:last_month_end].day.ordinalize}",
                               start_date: default_dates[:last_month_end],
                               end_date: default_dates[:last_month_end]
                           },
                           {
                               label: t('datepicker.range.custom'),
                               start_date: custom_start_date,
                               end_date: custom_start_date,
                               is_custom: true
                           }
                       ]
                     else
                       [
                           {
                               label: t('datepicker.range.this_month', month: default_dates[:this_month_start].to_date.strftime('%B')),
                               start_date: default_dates[:this_month_start],
                               end_date: default_dates[:today]
                           },
                           {
                               label: default_dates[:last_month_start].to_date.strftime('%B'),
                               start_date: default_dates[:last_month_start],
                               end_date: default_dates[:last_month_end]
                           },
                           {
                               label: t('datepicker.range.custom'),
                               start_date: custom_start_date,
                               end_date: custom_end_date,
                               is_custom: true
                           }
                       ]
                     end

    picker_presets.each do |preset|
      if preset[:start_date] == custom_start_date && preset[:end_date] == custom_end_date
        preset[:is_default] = true
        break
      end
    end
    picker_presets
  end

end
