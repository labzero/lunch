class CorporateCommunicationsController < ApplicationController

  before_action do
    @sidebar_options = [
        [I18n.t('messages.categories.all'), corporate_communications_path('all')],
        [I18n.t('messages.categories.investor_relations'), corporate_communications_path('investor_relations')],
        [I18n.t('messages.categories.accounting'), corporate_communications_path('accounting')],
        [I18n.t('messages.categories.products'), corporate_communications_path('products')],
        [I18n.t('messages.categories.collateral'), corporate_communications_path('collateral')],
        [I18n.t('messages.categories.community_program'), corporate_communications_path('community_program')],
        [I18n.t('messages.categories.community_works'), corporate_communications_path('community_works')],
        [I18n.t('messages.categories.educational'), corporate_communications_path('educational')]
    ]
    @filter = params[:category]
    raise 'invalid category' unless CorporateCommunication::VALID_CATEGORIES.include?(@filter) || @filter == 'all'
    @selected_category_label = t("messages.categories.#{@filter}")
  end

  def category
    message_service = MessageService.new
    @messages = message_service.corporate_communications(@filter)
  end

  def show
    if @filter == 'all'
      @message = CorporateCommunication.find(params[:id])
    else
      @message = CorporateCommunication.find_by!(id: params[:id], category: @filter)
    end
    message_service = MessageService.new
    messages_array = message_service.corporate_communications(@filter)
    messages_length = messages_array.count
    message_index = messages_array.index { |message| message.email_id == @message.email_id }
    # for linking to 'prior' and 'next' messages in a given category
    if message_index != 0 && (message_index + 1) < messages_length
      @prior_message = messages_array[message_index - 1]
      @next_message = messages_array[message_index + 1]
    elsif message_index == 0 && (message_index + 1) < messages_length
      @next_message = messages_array[message_index + 1]
    elsif message_index != 0 && (message_index + 1) == messages_length
      @prior_message = messages_array[message_index - 1]
    end
  end

end