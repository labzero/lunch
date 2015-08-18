require 'rails_helper'

describe DashboardHelper, type: :helper do
  let(:today){ Date.today}
  let(:maturity_date){ double('maturity_date',to_date: today) }
  let(:rate_data){ { interest_day_count: 1, maturity_date: maturity_date, payment_on: :payment_on} }
  let(:result){ helper.make_quick_advance_tooltip_data(rate_data)}

  let(:label){ t('dashboard.quick_advance.tooltip.maturity_date') }

  it 'should set appropriate fields on the returned hash' do
    allow(I18n).to receive(:t).and_return(:label)
    allow(helper).to receive(:fhlb_date_standard_numeric).with(today).and_return(:today_formatted)
    expect(result).to eq( { label => :today_formatted } )
  end
end