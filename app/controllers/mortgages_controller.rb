class MortgagesController < ApplicationController
  before_action do
    set_active_nav(:mortgages)
    @html_class ||= 'white-background'
  end

  before_action only: [:new] do
    authorize :mortgage, :request?
  end

  PLEDGE_TYPE_MAPPING = {
    specific: I18n.t('mortgages.new.transaction.pledge_types.specific'),
    blanket_lien: I18n.t('mortgages.new.transaction.pledge_types.blanket_lien')
  }.with_indifferent_access

  PLEDGE_TYPE_DROPDOWN = [[I18n.t('mortgages.new.transaction.pledge_types.specific'), 'specific']]
  
  BLANKET_LIEN_DROPDOWN_OPTION = [I18n.t('mortgages.new.transaction.pledge_types.blanket_lien'), 'blanket_lien']

  MCU_TYPE_MAPPING = {
    complete: I18n.t('mortgages.new.transaction.mcu_types.complete'),
    update: I18n.t('mortgages.new.transaction.mcu_types.update'),
    pledge: I18n.t('mortgages.new.transaction.mcu_types.pledge'),
    depledge: I18n.t('mortgages.new.transaction.mcu_types.depledge'),
    add: I18n.t('mortgages.new.transaction.mcu_types.add'),
    delete: I18n.t('mortgages.new.transaction.mcu_types.delete'),
    renumber: I18n.t('mortgages.new.transaction.mcu_types.renumber')
  }.with_indifferent_access

  PROGRAM_TYPE_MAPPING = {
    standard: I18n.t('mortgages.new.transaction.program_types.standard'),
    loans_held: I18n.t('mortgages.new.transaction.program_types.loans_held')
  }.with_indifferent_access

  STATUS_MAPPING = {
    processing: I18n.t('mortgages.view.transaction_details.status.processing'),
    review: I18n.t('mortgages.view.transaction_details.status.review'),
    committed: I18n.t('mortgages.view.transaction_details.status.committed'),
    canceled: I18n.t('mortgages.view.transaction_details.status.canceled')
  }.with_indifferent_access

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
  def manage
    @title = t('mortgages.manage.title')
    today = Time.zone.today
    @due_datetime = Time.zone.parse("#{(today + 7.days).iso8601} 17:00:00") # Needs to come from MCU service
    @extension_datetime = @due_datetime + 7.days # Needs to come from MCU service
    member_balances = MemberBalanceService.new(current_member_id, request)
    mcu_status = member_balances.mcu_member_status
    rows = if mcu_status.present?
      mcu_status.collect do |status|
        status = translated_mcu_transaction(status)
      {
        columns: [
          {value: status[:transaction_number], type: nil},
          {value: status[:translated_mcu_type], type: nil},
          {value: status[:authorized_by], type: nil},
          {value: status[:authorized_on], type: nil},
          {value: status[:translated_status], type: nil},
          {value: status[:number_of_loans], type: :number},
          {value: status[:number_of_errors], type: :number},
          {value: [[I18n.t('mortgages.manage.actions.view_details'), mcu_view_transaction_path(transaction_number: status[:transaction_number])]], type: :link_list}
        ]
      }
      end
    else
      []
    end
    @table_data = {
      column_headings: [
        t('mortgages.manage.transaction_number'),
        t('mortgages.manage.upload_type'),
        t('mortgages.manage.authorized_by'),
        t('mortgages.manage.authorized_on'),
        t('mortgages.manage.status'),
        t('mortgages.manage.number_of_loans'),
        t('mortgages.manage.number_of_errors'),
        t('mortgages.manage.action')
      ],
      rows: rows
    }
  end

  # GET
  def new
    @title = t('mortgages.new.title')
    @member_info = MemberBalanceService.new(current_member_id, request).mcu_member_info
    @due_datetime = Time.zone.parse(@member_info['mcuDueDate'])
    @extension_datetime = Time.zone.parse(@member_info['mcuExtendedDate'])
    @pledge_type_dropdown_options = PLEDGE_TYPE_DROPDOWN
    @pledge_type_dropdown_options << BLANKET_LIEN_DROPDOWN_OPTION if @member_info['blanketLien']
    @pledge_type_dropdown_options.uniq!
    file_types = @member_info['mcuuFileTypes']
    @mcu_type_dropdown_options = file_types.map { |type| type['nameSpecific'] }.zip(file_types.map { |type| type['value'] })
    @program_type_dropdowns = Hash[file_types.map { |type| type['value'] }.zip(file_types.map { |type| [[type['pledgeTypes'][0], type['pledgeTypes'][0]]] })]
    @accepted_upload_mimetypes = ACCEPTED_UPLOAD_MIMETYPES.join(', ')
    @session_elevated = session_elevated?
  end

  # GET
  def view
    @title = t('mortgages.view.title')
    member_balances = MemberBalanceService.new(current_member_id, request)
    mcu_transactions = member_balances.mcu_member_status
    raise StandardError, 'There has been an error and MortgagesController#view has encountered nil. Check error logs.' if mcu_transactions.nil?
    transaction_details = mcu_transactions.select{ |transaction| transaction[:transaction_number].to_s == params[:transaction_number].to_s}.first
    raise ArgumentError, "No matching MCU Status found for MCU with transaction_number: #{params[:transaction_number]}" unless transaction_details.present?
    @transaction_details = translated_mcu_transaction(transaction_details)
  end

  private

  def translated_mcu_transaction(transaction)
    if transaction
      transaction[:translated_mcu_type] = MCU_TYPE_MAPPING[transaction[:mcu_type]] if transaction[:mcu_type]
      transaction[:translated_pledge_type] = PLEDGE_TYPE_MAPPING[transaction[:pledge_type]] if transaction[:pledge_type]
      transaction[:translated_program_type] = PROGRAM_TYPE_MAPPING[transaction[:program_type]] if transaction[:program_type]
      transaction[:translated_status] = STATUS_MAPPING[transaction[:status]] if transaction[:status]
      transaction[:error_percentage] = ((transaction[:number_of_errors].to_f / transaction[:number_of_loans].to_f) * 100 if transaction[:number_of_loans])
      transaction.with_indifferent_access
    end
  end
end