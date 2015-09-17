RSpec.shared_examples 'a date restricted report' do |action, default_start_selection=nil|
  let(:start_date) { rand(500).days.ago(Time.zone.today) }
  if default_start_selection
    default_start = case default_start_selection
      when :last_month_start
        ['beginning of last month', default_dates_hash[:last_month_start]]
      when :last_month_end
        ['end of last month', default_dates_hash[:last_month_end]]
      else
        raise 'Default start case not found'
    end
    it "should pass the `min_and_start_dates` method the #{default_start.first} if the `start_date` param is not provided" do
      expect(controller).to receive(:min_and_start_dates).with(anything, default_start.last)
      get action
    end
  end
  it 'should pass the `min_and_start_dates` method the `start_date` param if provided' do
    expect(controller).to receive(:min_and_start_dates).with(anything, start_date)
    get action, start_date: start_date
  end
  it 'should set @min_date to the `min_date` attribute of the `min_and_start_dates` hash' do
    get action
    expect(assigns[:min_date]).to eq(min_date)
  end
end