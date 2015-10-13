module ErrorHelpers

  def ignoring_errors(*errors)
    begin
      yield
    rescue *errors
      
    end
  end

end

RSpec.configure do |config|
  config.include ErrorHelpers
end