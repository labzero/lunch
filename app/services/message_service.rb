class MessageService

  def corporate_communications(filter='all')
    filter = filter.to_s
    valid_filters = %w(misc investor_relations products credit technical_updates community)
    if filter == 'all' || !valid_filters.include?(filter)
      CorporateCommunication.all
    else
      CorporateCommunication.where(category: filter)
    end
  end
end