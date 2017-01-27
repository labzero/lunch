class LetterOfCredit
  include ActiveModel::Model

  # The DEFAULT_ISSUANCE_FEE and DEFAULT_MAINTENANCE_FEE may eventually come from a service, but we have been asked by
  # Scott and Michael to hardcode them in until an appropriate service is built to expose this information.
  DEFAULT_ISSUANCE_FEE = 100
  DEFAULT_MAINTENANCE_FEE = '10 bps'

  ACCESSIBLE_ATTRS = [:lc_number, :beneficiary_name, :beneficiary_address, :amount, :issue_date, :expiration_date, :issuance_fee, :maintenance_fee]

  attr_accessor *ACCESSIBLE_ATTRS

  def initialize
    @issuance_fee = DEFAULT_ISSUANCE_FEE
    @maintenance_fee = DEFAULT_MAINTENANCE_FEE
  end
end