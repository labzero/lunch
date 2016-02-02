class Member

  attr_reader :id

  def initialize(id)
    raise ArgumentError.new('`id` must not be nil') unless id
    @id = id
  end

  def flipper_id
    "FHLB-#{id}" if id
  end

end