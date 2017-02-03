class BeneficiariesService < MAPIService
  BENEFICIARIES = (ENV['LC_BENEFICIARIES'].present? ? JSON.parse(ENV['LC_BENEFICIARIES']) : []).freeze

  def all
    BENEFICIARIES.collect{|x| x.with_indifferent_access}
  end
end