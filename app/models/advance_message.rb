class AdvanceMessage
  include ActiveModel::Model

  validates :content, presence: true
  validates :date, presence: true

  attr_accessor :content, :date

  def self.all
    messages = []
    message_seeds = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'advance_messages.json')))
    message_seeds.each do |seed|
      messages << new({date: seed.first.to_date, content: seed.last})
    end
    messages
  end
  
  def self.quick_advance_message_for(date)
    all.find { |message| message.date == date }.try(:content)
  end
  
end