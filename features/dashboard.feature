Feature: Visiting the Dashboard
  As a user
  I want to use visit the dashboard for the FHLB Member Portal
  In order to find information

Background:
  Given I am logged in

@smoke
Scenario: Visit dashboard
  When I visit the dashboard
  Then I should see dashboard modules

Scenario: See dashboard contacts
  When I visit the dashboard
  Then I should see 3 contacts

@smoke @jira-mem-610 @jira-mem-1126 @flip-on-recent-credit-activity
Scenario: See required dashboard modules
  When I visit the dashboard
  And I should see a market overview graph
  And I should see the "recent activities" section in its loaded state
  And I should see the "account overview" section in its loaded state
  And I should see an "borrowing capacity gauge" in the Account module

@data-unavailable @jira-mem-408
Scenario: Data for Aggregate 30 Day Terms module is temporarily unavailable
  Given I visit the dashboard
  When there is no data for "Aggregate 30 Day Terms"
  Then the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state

@jira-mem-1330 @flip-on-report-capital-stock-position-and-leverage
Scenario: User visits report pages from the Account Overview module
  Given I am on the dashboard with the account overview in its loaded state
  When I click on the STA Balance link in the account overview
  Then I should be on the "Settlement Transaction" report page
  When I am on the dashboard with the account overview in its loaded state
  And I click on the Borrowing Capacity link in the account overview
  Then I should be on the "Borrowing Capacity" report page
  When I am on the dashboard with the account overview in its loaded state
  And I click on the Stock Leverage link in the account overview
  Then I should be on the "Capital Stock Position and Leverage" report page
  And I am on the dashboard with the account overview in its loaded state
  And I click on the Account Summary link in the account overview
  Then I should be on the "Account Summary" report page

@jira-mem-1315 @local-only @flip-on-quick-reports
Scenario: Users can download pregenreated reports
  Given I am logged in to a bank with Quick Reports
  When I visit the dashboard
  Then I should see the "quick reports" section in its loaded state
  And I should see a list of downloadedable quick reports
