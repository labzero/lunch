class MAPIService::Error
  attr_reader :type, :code, :value

  def initialize(type, code, value=nil)
    @type = type
    @code = code
    @value = value
  end

end