class BeneficiariesService < MAPIService

  def beneficiaries(member_id)
    if beneficiaries = get_json(:beneficiaries, "member/#{member_id}/beneficiaries").collect{|x| x.with_indifferent_access}
      format_beneficiaries(beneficiaries)
    end
  end

  private

  def format_beneficiaries(beneficiaries)
    beneficiaries.collect do |beneficiary|
      care_of = beneficiary[:CARE_OF].blank? ? '' : "\nc/o " + beneficiary[:CARE_OF].to_s if beneficiary[:CARE_OF]
      department = beneficiary[:DEPARTMENT].blank? ? '' : "\n" + beneficiary[:DEPARTMENT].to_s if beneficiary[:DEPARTMENT]
      {
        name: (beneficiary[:BENEFICIARY_SHORT_NAME].to_s unless beneficiary[:BENEFICIARY_SHORT_NAME].blank? if beneficiary[:BENEFICIARY_SHORT_NAME]),
        address: beneficiary[:BENEFICIARY_FULL_NAME].to_s + care_of.to_s + department.to_s + "\n" + beneficiary[:STREET].to_s + "\n" + beneficiary[:CITY].to_s + ', ' + beneficiary[:STATE].to_s + ' ' + beneficiary[:ZIP].to_s
      }
    end
  end

end