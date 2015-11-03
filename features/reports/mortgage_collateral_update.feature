@jira-mem-69
Feature: Visiting the Mortgage Collateral Update Report Page
  As a user
  I want to use visit the mortgage collateral update report page for the FHLB Member Portal
  In order to the status of the bank's most recent mortgage collateral update

Background:
  Given I am logged in

@smoke @jira-mem-263
Scenario: Visit mortgage collateral update report from header link
  Given I visit the dashboard
  When I select "MCU Status" from the reports dropdown
  Then I should see "Mortgage Collateral Update (MCU) Status"
  And I should see a report header with just freshness
  And I should see 3 report tables with multiple data rows

@data-unavailable @jira-mem-283 @jira-mem-263
Scenario: No data is available to show in the mortgage collateral update report
  Given I am on the "Mortgage Collateral Update" report page
  When the "Mortgage Collateral Update" table has no data
  Then I should see an empty report table with No Records messaging

@data-unavailable @jira-mem-282 @jira-mem-263
Scenario: The mortgage collateral update report has been disabled
  Given I am on the "Mortgage Collateral Update" report page
  When the "Mortgage Collateral Update" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging
