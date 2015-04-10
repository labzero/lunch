class CorporateCommunicationsController < ApplicationController

  before_action do
    message_service = MessageService.new
    @sidebar_options = [
        [I18n.t('settings.email.all.title'), corporate_communications_path('all'), message_service.corporate_communications('all').count == 0],
        [I18n.t('settings.email.investor_relations.title'), corporate_communications_path('investor_relations'), message_service.corporate_communications('investor_relations').count == 0],
        [I18n.t('settings.email.accounting.title'), corporate_communications_path('accounting'), message_service.corporate_communications('accounting').count == 0],
        [I18n.t('settings.email.products.title'), corporate_communications_path('products'), message_service.corporate_communications('products').count == 0],
        [I18n.t('settings.email.collateral.title'), corporate_communications_path('collateral'), message_service.corporate_communications('collateral').count == 0],
        [I18n.t('settings.email.community_program.title'), corporate_communications_path('community_program'), message_service.corporate_communications('community_program').count == 0],
        [I18n.t('settings.email.community_works.title'), corporate_communications_path('community_works'), message_service.corporate_communications('community_works').count == 0],
        [I18n.t('settings.email.educational.title'), corporate_communications_path('educational'), message_service.corporate_communications('educational').count == 0]
    ]
    @filter = params[:category]
    raise 'invalid category' unless CorporateCommunication::VALID_CATEGORIES.include?(@filter) || @filter == 'all'
    @selected_category_label = t("settings.email.#{@filter}.title")
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