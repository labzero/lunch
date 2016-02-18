require 'rails_helper'

RSpec.describe MemberBalanceTodaysCreditActivityJob, type: :job do
  it_behaves_like 'a job that makes service calls', MemberBalanceService, :todays_credit_activity
end
