class MortgagesController < ApplicationController
  before_action do
    set_active_nav(:mortgages)
    @html_class ||= 'white-background'
    authorize :mortgage, :request?
  end

  PLEDGE_TYPE_DROPDOWN = [
    [I18n.t('mortgages.new.transaction.pledge_types.specific'), 'specific'],
    [I18n.t('mortgages.new.transaction.pledge_types.blanket_lien'), 'blanket_lien']
  ].freeze

  MCU_TYPE_DROPDOWN = [
    [I18n.t('mortgages.new.transaction.mcu_types.complete'), 'complete'],
    [I18n.t('mortgages.new.transaction.mcu_types.update'), 'update'],
    [I18n.t('mortgages.new.transaction.mcu_types.pledge'), 'pledge'],
    [I18n.t('mortgages.new.transaction.mcu_types.depledge'), 'depledge'],
    [I18n.t('mortgages.new.transaction.mcu_types.add'), 'add'],
    [I18n.t('mortgages.new.transaction.mcu_types.delete'), 'delete'],
    [I18n.t('mortgages.new.transaction.mcu_types.renumber'), 'renumber']
  ].freeze

  PROGRAM_TYPE_DROPDOWN = [
    [I18n.t('mortgages.new.transaction.program_types.standard'), 'standard'],
    [I18n.t('mortgages.new.transaction.program_types.loans_held'), 'loans_held']
  ].freeze

  ACCEPTED_UPLOAD_MIMETYPES = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'text/csv',
    'application/vnd.oasis.opendocument.spreadsheet',
    'text/plain',
    'application/x-compressed',
    'application/x-zip-compressed',
    'application/zip',
    'multipart/x-zip'
  ].freeze

  # GET
  def new
    @title = t('mortgages.new.title')
    today = Time.zone.today
    @due_datetime = Time.zone.parse("#{(today + 7.days).iso8601} 17:00:00") # Needs to come from MCU service
    @extension_datetime = @due_datetime + 7.days # Needs to come from MCU service
    @pledge_type_dropdown_options = PLEDGE_TYPE_DROPDOWN
    @mcu_type_dropdown_options = MCU_TYPE_DROPDOWN
    @program_type_dropdown_options = PROGRAM_TYPE_DROPDOWN
    @accepted_upload_mimetypes = ACCEPTED_UPLOAD_MIMETYPES.join(', ')
    @session_elevated = session_elevated?
  end
end