module DatePickerHelper

  def default_dates_hash
    today = Time.zone.now.to_date
    {
      this_month_start: today.beginning_of_month,
      today: today,
      last_month_start: today.beginning_of_month - 1.month,
      last_month_end: (today.beginning_of_month - 1.month).end_of_month,
      this_year_start: today.beginning_of_year,
      last_year_start: (today - 1.year).beginning_of_year,
      last_year_end: (today - 1.year).end_of_year
    }
  end

  def current_quarter
    today = Time.zone.now.to_date
    {quarter: (today.month / 3.0).ceil, year: today.year}
  end

  def last_quarter
    today = Time.zone.now.to_date
    quarter = (today.month / 3.0).ceil
    if quarter == 1
      quarter = 4
      year = today.year - 1.year
    else
      quarter = quarter - 1
      year = today.year
    end
    {quarter: quarter, year: year}
  end

  def quarter_start_and_end_dates(quarter, year)
    case quarter
      when 1
        start_date = "#{year}-01-01".to_date
        end_date = "#{year}-03-31".to_date
      when 2
        start_date = "#{year}-04-01".to_date
        end_date = "#{year}-06-30".to_date
      when 3
        start_date = "#{year}-07-01".to_date
        end_date = "#{year}-09-30".to_date
      when 4
        start_date = "#{year}-10-01".to_date
        end_date = "#{year}-12-31".to_date
    end
    {start_date: start_date, end_date: end_date}
  end

  def date_picker_presets(custom_start_date, custom_end_date = nil)
    presets = if custom_end_date.nil?
      date_picker_single(custom_start_date)
    else
      date_picker_range(custom_start_date, custom_end_date)
    end
    presets.each do |preset|
      if preset[:start_date] == custom_start_date && (preset[:end_date] == custom_end_date || custom_end_date.nil?)
        preset[:is_default] = true
        break
      end
    end
    presets
  end

  def date_picker_range(custom_start_date, custom_end_date)
    [
      {
        label: t('datepicker.range.date_to_current', date: default_dates_hash[:this_month_start].to_date.strftime('%B')),
        start_date: default_dates_hash[:this_month_start],
        end_date: default_dates_hash[:today]
      },
      {
        label: default_dates_hash[:last_month_start].to_date.strftime('%B'),
        start_date: default_dates_hash[:last_month_start],
        end_date: default_dates_hash[:last_month_end]
      },
      {
        label: t('datepicker.range.date_to_current', date: t("dates.quarters.#{current_quarter[:quarter]}", year: current_quarter[:year])),
        start_date: quarter_start_and_end_dates((current_quarter[:quarter]), current_quarter[:year])[:start_date],
        end_date: default_dates_hash[:today]
      },
      {
        label: t("dates.quarters.#{last_quarter[:quarter]}", year: last_quarter[:year]),
        start_date: quarter_start_and_end_dates(last_quarter[:quarter], last_quarter[:year])[:start_date],
        end_date: quarter_start_and_end_dates(last_quarter[:quarter], last_quarter[:year])[:end_date]
      },
      {
        label: t('datepicker.range.date_to_current', date: default_dates_hash[:this_year_start].year),
        start_date: default_dates_hash[:this_year_start],
        end_date: default_dates_hash[:today]
      },
      {
        label: default_dates_hash[:last_year_start].year.to_s + ' ',
        start_date: default_dates_hash[:last_year_start],
        end_date: default_dates_hash[:last_year_end]
      },
      {
        label: t('datepicker.range.custom'),
        start_date: custom_start_date,
        end_date: custom_end_date,
        is_custom: true
      }
    ]
  end

  def date_picker_single(custom_start_date)
    [
      {
        label: t('global.today'),
        start_date: default_dates_hash[:today],
        end_date: default_dates_hash[:today]
      },
      {
        label: t('datepicker.single.end_of', date: default_dates_hash[:last_month_end].strftime('%B')),
        start_date: default_dates_hash[:last_month_end],
        end_date: default_dates_hash[:last_month_end]
      },
      {
        label: t('datepicker.single.end_of', date: t("dates.quarters.#{last_quarter[:quarter]}", year: last_quarter[:year])),
        start_date: quarter_start_and_end_dates((last_quarter[:quarter]), last_quarter[:year])[:end_date],
        end_date: quarter_start_and_end_dates((last_quarter[:quarter]), last_quarter[:year])[:end_date]
      },
      {
        label: t('datepicker.single.end_of', date: default_dates_hash[:last_year_start].year.to_s),
        start_date: default_dates_hash[:last_year_end],
        end_date: default_dates_hash[:last_year_end]
      },
      {
        label: t('datepicker.single.custom'),
        start_date: custom_start_date,
        end_date: custom_start_date,
        is_custom: true
      }
    ]
  end

end
