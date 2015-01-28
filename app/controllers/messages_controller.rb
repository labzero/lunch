class MessagesController < ApplicationController

  def index
    @sidebar_options = [
        [t('messages.categories.all'), 'all'],
        [t('messages.categories.investor_relations'), 'investor_relations'],
        [t('messages.categories.misc'), 'misc'],
        [t('messages.categories.products'), 'products'],
        [t('messages.categories.credit'), 'credit'],
        [t('messages.categories.technical_updates'), 'technical_updates'],
        [t('messages.categories.community'), 'community']
    ]
    @filter = params[:messages_filter]
    valid_categories = @sidebar_options.map { |option| option.last }
    @filter = 'all' unless valid_categories.include?(@filter)
    message_service = MessageService.new
    @messages = message_service.corporate_communications(@filter)
  end

end