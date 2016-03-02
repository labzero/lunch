module DatePickerHelper

  def default_dates_hash(today=Time.zone.today)
    {
      this_month_start: today.beginning_of_month,
      this_month_end: today.end_of_month,
      today: today,
      last_30_days: today - 1.month,
      last_month_start: today.beginning_of_month - 1.month,
      last_month_end: (today.beginning_of_month - 1.month).end_of_month,
      this_year_start: today.beginning_of_year,
      last_year_start: (today - 1.year).beginning_of_year,
      last_year_end: (today - 1.year).end_of_year
    }
  end

  def current_quarter
    today = Time.zone.today
    {quarter: (today.month / 3.0).ceil, year: today.year}
  end

  def last_quarter
    today = Time.zone.today
    quarter = (today.month / 3.0).ceil
    if quarter == 1
      quarter = 4
      year = today.year - 1
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

  def date_picker_presets(custom_start_date, custom_end_date = nil, date_history = nil, max_date = nil)
    min_date = Time.zone.today - date_history if date_history
    presets = if custom_end_date.nil?
      date_picker_single(custom_start_date, min_date, max_date)
    else
      date_picker_range(custom_start_date, custom_end_date, min_date, max_date)
    end
    presets.each do |preset|
      if preset[:start_date] == custom_start_date && (preset[:end_date] == custom_end_date || custom_end_date.nil?)
        preset[:is_default] = true
        break
      end
    end
    presets
  end

  def date_picker_range(custom_start_date, custom_end_date, min_date, max_date)
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
        label: t('datepicker.range.last_30_days'),
        start_date: default_dates_hash[:last_30_days],
        end_date: default_dates_hash[:today]
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
    ].delete_if do |preset|
      (preset[:start_date] < min_date if min_date) ||
      (preset[:start_date] > max_date if max_date)
    end
  end

  def date_picker_single(custom_start_date, min_date, max_date)
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
    ].delete_if do |preset|
      (preset[:start_date] < min_date if min_date) ||
      (preset[:start_date] > max_date if max_date)
    end
  end

  def most_recent_business_day(d)
    return d - 1.day if d.saturday?
    return d - 2.day if d.sunday?
    d
  end

  def min_and_start_dates(min_date_range, start_date_param=nil)
    now = Time.zone.today
    start_date = (start_date_param || now).to_date
    min_date = now - min_date_range

    start_date = if min_date < start_date && start_date <= now
      start_date
    elsif start_date > now
      now
    else
      min_date
    end
    [min_date, start_date]
  end

  def month_restricted_start_date(start_date)
    today = Time.zone.today
    if start_date > today.beginning_of_month && start_date != today.end_of_month
      (start_date - 1.month).end_of_month
    else
      start_date.end_of_month
    end
  end
  
  def last_month_end
    today = Time.zone.today
    today == today.end_of_month ? today.end_of_month : (today - 1.month).end_of_month
  end
end