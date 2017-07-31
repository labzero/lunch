class Member

  FLIPPER_PREFIX = 'FHLB-'.freeze

  DEFAULT_REPORT_LIST = {
    account_summary: {},
    advances_detail: {
      start_date: :this_month_end
    },
    borrowing_capacity: {
      as_of: :last_month_end,
      disable_until_data_available: true
    },
    settlement_transaction_account: {
      start_date: :this_month_start,
      end_date: :this_month_end
    },
    securities_transactions: {
      start_date: :this_month_end
    }
  }.with_indifferent_access.freeze

  attr_reader :id
  alias :member_id :id

  def initialize(id)
    raise ArgumentError.new('`id` must not be nil') unless id
    @id = id
  end

  def flipper_id
    "#{FLIPPER_PREFIX}#{id}" if id
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

  def requires_dual_signers?(request=nil)
    fetch_details(request) unless @member_details.present?
    @member_details[:dual_signers_required]
  end

  def name(request=nil)
    fetch_details(request) unless @member_details.present?
    @member_details[:name]
  end

  def found?(request=nil)
    fetch_details(request) unless @member_details.present?
    !!@member_details
  end

  protected

  def fetch_details(request=nil)
    @member_details = MembersService.new(request || ActionDispatch::TestRequest.new).member(id)
  end

end