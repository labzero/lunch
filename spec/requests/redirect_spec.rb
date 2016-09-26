require 'rails_helper'

RSpec.describe 'Redirecting from old URLs', :type => :request do
  describe 'discrete redirects' do
    {
      '/Default.aspx' => '/dashboard',
      '/member/index.aspx' => '/dashboard',
      '/member/reports/sta/monthly.aspx' => '/reports/settlement-transaction-account',
      '/member/rates/current/default.aspx' => '/reports/current-price-indications',
      '/member/reports/securities/transaction.aspx' => '/reports/securities-transactions',
      '/member/reports/advances/advances.aspx' =>	'/reports/advances',
      '/member/profile/overview.aspx' => '/reports/account-summary',
      '/member/profile/collateral/collateral.aspx' => '/reports/borrowing-capacity',
      '/member/reports/advances/today.aspx' => '/reports/todays-credit',
      '/member/profile/sta/sta.aspx' => '/reports/settlement-transaction-account'
    }.each do |route, redirect|
      it "redirects `#{route}` to `#{redirect}`" do
        get route
        expect(response).to redirect_to(redirect)
      end
      it "redirects `#{route}` with status of 302" do
        get route
        expect(response).to have_http_status(302)
      end
    end
  end
  describe 'wildcard redirects' do
    {
      '/accountservices' => '/reports/account-summary',
      '/member/ps/forms' => '/resources/forms',
      '/member/ps/guides' => '/resources/guides',
      '/member/ps' => '/products/summary',
      '/member/etransact' => '/advances/manage',
      '/member/accessmanager' => '/settings/users',
      '/member/reports' => '/reports'
    }.each do |route, redirect|
      it "redirects `#{route}` to `#{redirect}`" do
        get route
        expect(response).to redirect_to(redirect)
      end
      it "redirects any descendant URL of `#{route}` to '#{redirect}'" do
        descendant_route = route + "/#{SecureRandom.hex}/#{SecureRandom.hex}"
        get descendant_route
        expect(response).to redirect_to(redirect)
      end
      it "redirects `#{route}` with status of 302" do
        get route
        expect(response).to have_http_status(302)
      end
    end
  end
  describe 'unmatched `member` URLS' do
    it "redirects any unmatched descendant URL of `member` to '/dashboard'" do
      get "/member/#{SecureRandom.hex}"
      expect(response).to redirect_to('/dashboard')
    end
    it "redirects any unmatched descendant URL of `member` with status of 302" do
      get "/member/#{SecureRandom.hex}"
      expect(response).to have_http_status(302)
    end
  end
end

