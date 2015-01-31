class CorporateCommunicationsController < ApplicationController

  def category
    set_standard_corp_com_instance_variables(params[:category])
    message_service = MessageService.new
    @messages = message_service.corporate_communications(@filter)
  end

  def show
    set_standard_corp_com_instance_variables(params[:category])
    @message = CorporateCommunication.find(params[:id])
  end

  private
  def set_standard_corp_com_instance_variables(category_param)
    @sidebar_options = [
        [I18n.t('messages.categories.all'), corporate_communications_path('all')],
        [I18n.t('messages.categories.investor_relations'), corporate_communications_path('investor_relations')],
        [I18n.t('messages.categories.misc'), corporate_communications_path('misc')],
        [I18n.t('messages.categories.products'), corporate_communications_path('products')],
        [I18n.t('messages.categories.credit'), corporate_communications_path('credit')],
        [I18n.t('messages.categories.technical_updates'), corporate_communications_path('technical_updates')],
        [I18n.t('messages.categories.community'), corporate_communications_path('community')]
    ]
    @filter = category_param
    @filter = 'all' unless CorporateCommunication::VALID_CATEGORIES.include?(@filter)
    @selected_category_label = t("messages.categories.#{@filter}")
  end

end