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
  And I should see an "borrowing capacity gauge" in the Account module
  And I should see a market overview graph
  And I should see the "recent activities" section in its loaded state
  And I should see the "account overview" section in its loaded state

@data-unavailable @jira-mem-408
Scenario: Data for Aggregate 30 Day Terms module is temporarily unavailable
  Given I visit the dashboard
  When there is no data for "Aggregate 30 Day Terms"
  Then the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state
