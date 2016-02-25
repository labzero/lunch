class Member

  DEFAULT_REPORT_LIST = {
    account_summary: {},
    advances_detail: {
      start_date: :this_month_end
    },
    borrowing_capacity: {},
    settlement_transaction_account: {
      start_date: :this_month_start,
      end_date: :this_month_end
    }
  }.with_indifferent_access.freeze

  attr_reader :id
  alias :member_id :id

  def initialize(id)
    raise ArgumentError.new('`id` must not be nil') unless id
    @id = id
  end

  def flipper_id
    "FHLB-#{id}" if id
  end

  def latest_report_set
    QuickReportSet.for_member(id).latest
  end

  def report_set_for_period(period)
    QuickReportSet.for_member(id).for_period(period).first_or_create
  end

  def quick_report_list
    DEFAULT_REPORT_LIST.keys
  end

  def quick_report_params(report_name)
    DEFAULT_REPORT_LIST[report_name]
  end

end