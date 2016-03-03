class ReportCurrentPriceIndicationsJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id, uuid = nil)
    uuid ||= job_id
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    rate_service = RatesService.new(request)
    member_balances = MemberBalanceService.new(member_id, request)
    {
      standard_vrc_data: rate_service.current_price_indications('standard', 'vrc'),
      sbc_vrc_data: rate_service.current_price_indications('sbc', 'vrc'),
      standard_frc_data: rate_service.current_price_indications('standard', 'frc'),
      sbc_frc_data: rate_service.current_price_indications('sbc', 'frc'),
      standard_arc_data: rate_service.current_price_indications('standard', 'arc'),
      sbc_arc_data: rate_service.current_price_indications('sbc', 'arc'),
      sta_data: member_balances.settlement_transaction_rate
    }
  end
end
