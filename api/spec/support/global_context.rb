module MAPI
  module RSpec
    module GlobalContext
      extend ::RSpec::SharedContext

      let(:member_id) { 750 }
      before do
        header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
      end
    end
  end
end
