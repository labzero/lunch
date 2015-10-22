class MessageService

  def corporate_communications(filter='all')
    filter = filter.to_s
    if filter == 'all' || !CorporateCommunication::VALID_CATEGORIES.include?(filter)
      CorporateCommunication.all
    else
      CorporateCommunication.where(category: filter)
    end
  end
  
  def todays_quick_advance_message
    AdvanceMessage.quick_advance_message_for(Time.zone.today)
  end
  
end