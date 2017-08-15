class AdvanceMessage
  include ActiveModel::Model

  validates :content, presence: true
  validates :date, presence: true

  attr_accessor :content, :date

  def self.all
    messages = []
    calendar_service = CalendarService.new(nil)
    early_shutoffs = EtransactAdvancesService.new(nil).early_shutoffs
    early_shutoffs.each do |early_shutoff|
      if early_shutoff[:day_before_message].present?
        previous_business_day = calendar_service.find_previous_business_day(early_shutoff[:early_shutoff_date] - 1.day, 1.day)
        (previous_business_day...early_shutoff[:early_shutoff_date]).to_a.each do |date|
          messages << new({date: date, content: early_shutoff[:day_before_message]})
        end
      end
    end
    early_shutoffs.each do |early_shutoff|
      if early_shutoff[:day_of_message]
        date = early_shutoff[:early_shutoff_date]
        message = messages.find {|existing_message| existing_message.date == date} || new({date: date})
        message.content = early_shutoff[:day_of_message]
        messages << message
      end
    end
    messages
  end
  
  def self.quick_advance_message_for(date)
    all.find { |message| message.date == date }.try(:content)
  end
  
end