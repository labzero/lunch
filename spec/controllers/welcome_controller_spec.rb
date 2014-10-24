require 'rails_helper'

RSpec.describe WelcomeController, :type => :controller do
  describe "GET details" do
    describe "without a REVISION file" do
      before { `rm ./REVISION` }
      it "should return an error" do
        get :details
        expect(response.body).to match('No REVISION found!')
      end
    end
    describe "with a REVISION file" do
      before { `echo 'TEST123' > ./REVISION` }
      after { `rm ./REVISION` }
      it "should return the contents" do
        get :details
        expect(response.body).to match('TEST123')
      end
    end
  end
end
