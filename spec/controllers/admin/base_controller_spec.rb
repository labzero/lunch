require 'rails_helper'

RSpec.describe Admin::BaseController, :type => :controller do

 it_behaves_like 'an admin controller'

  context 'private methods' do
    describe '`require_admin`' do
      it 'authorizes the current user with the `WebAdminPolicy`' do
        expect(subject).to receive(:authorize).with(:web_admin, :show?)
        subject.send(:require_admin)
      end
    end
  end

end