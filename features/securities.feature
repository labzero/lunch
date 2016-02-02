Feature: Using the Securities tab
  As a user
  I want to use the Securities tab
  To visit the old FHLB web-site

Background:
  Given I am logged in

@smoke @jira-mem-1295 @flip-on-securities
Scenario: Visit Manage Securities from the header
  Given I visit the dashboard
  When I click on the Securities link in the header
  Then I should be on the Manage Securities page
  Then I should see a report table with multiple data rows
