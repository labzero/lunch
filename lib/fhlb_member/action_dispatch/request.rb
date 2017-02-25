module FhlbMember
  module ActionDispatch
    module Request
      def user_id
        warden_user = session[ApplicationController::SessionKeys::WARDEN_USER]
        warden_user[0][0] if warden_user
      end

      def member_id
        session[ApplicationController::SessionKeys::MEMBER_ID]
      end

      def member_name
        session[ApplicationController::SessionKeys::MEMBER_NAME]
      end
    end
  end
end