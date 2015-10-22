module FHLBMember
  class FailureApp < Devise::FailureApp

    protected
    
    def store_location!
      super unless request.xhr?
    end
  end
end