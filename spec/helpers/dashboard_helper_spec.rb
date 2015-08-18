require 'rails_helper'

describe DashboardHelper, type: :helper do
  let(:today){ Date.today}
  let(:maturity_date){ double('maturity_date',to_date: today) }
  let(:rate_data){ { interest_day_count: 1, maturity_date: maturity_date, payment_on: :payment_on} }
  let(:result){ helper.make_quick_advance_tooltip_data(rate_data)}

  let(:label1){ t('dashboard.quick_advance.tooltip.payment_on') }
  let(:label2){ t('dashboard.quick_advance.tooltip.interest_day_count') }
  let(:label3){ t('dashboard.quick_advance.tooltip.maturity_date') }
  let(:label4){ t("dashboard.quick_advance.table.#{rate_data[:interest_day_count]}") }

  it 'should set appropriate fields on the returned hash' do
    allow(I18n).to receive(:t).and_return(:label1, :label2, :label3, :label4)
    allow(helper).to receive(:fhlb_date_standard_numeric).with(today).and_return(:today_formatted)
    expect(result).to eq( { label1 => :payment_on, label2 => label4, label3 => :today_formatted } )
  end
end