require 'rails_helper'

describe DashboardHelper, type: :helper do
  let(:today){ Date.today}
  let(:maturity_date){ double('maturity_date',to_date: today) }
  let(:rate_data){ { interest_day_count: 1, maturity_date: maturity_date, payment_on: :payment_on} }
  let(:advance_term) { double('advance_term', to_sym: nil)}
  let(:result){ helper.make_quick_advance_tooltip_data(rate_data, advance_term)}

  let(:label){ t('dashboard.quick_advance.tooltip.maturity_date') }

  it 'should set appropriate fields on the returned hash' do
    allow(I18n).to receive(:t).and_return(:label)
    allow(helper).to receive(:fhlb_date_standard_numeric).with(today).and_return(:today_formatted)
    expect(result).to eq( { label => :today_formatted } )
  end
  it "returns #{I18n.t('dashboard.quick_advance.table.axes_labels.open')} if it is passed an `open` advance_term" do
    allow(advance_term).to receive(:to_sym).and_return(:open)
    expect(result).to eq( { label => t('dashboard.quick_advance.table.axes_labels.open') } )
  end
end