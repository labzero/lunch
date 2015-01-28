class MessageService

  def corporate_communications(filter='all')
    filter = filter.to_s
    if filter == 'all' || !CorporateCommunication::VALID_CATEGORIES.include?(filter)
      CorporateCommunication.all
    else
      CorporateCommunication.where(category: filter)
    end
  end
end