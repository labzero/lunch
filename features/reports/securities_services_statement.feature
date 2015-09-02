@jira-mem-69
Feature: Visiting the Securities Services Monthly Statement Page
  As a user
  I want to use visit the Securities Services Monthly Statement page for the FHLB Member Portal
  In order to view my account charges.

Background:
  Given I am logged in

@smoke @jira-mem-536
Scenario: Member sees Securities Services Statement
  Given I visit the dashboard
  When I select "Securities Services Monthly Statement" from the reports dropdown
  Then I should see report summary data
  And I should see 4 report tables with multiple data rows

@smoke @jira-mem-931
Scenario: The datepicker on the Securities Services Monthly Statement defaults to end of last month
  Given I am on the "Securities Services Monthly Statement" report page
  When I click the datepicker field
  Then I should see the end of last month as the default datepicker option

@data-unavailable @jira-mem-536
Scenario: No data is available to show in the Securities Services Statement
  Given I am on the "Securities Services Statement" report page
  When the "Dividend Summary" table has no data
  Then I should see a "Dividend Summary" report table with all data missing
  When the "Dividend Details" table has no data
  Then I should see the "Dividend Details" report table with Data Unavailable messaging

@data-unavailable @jira-mem-536
Scenario: The Securities Services Statement has been disabled
  Given I am on the "Securities Services Statement" report page
  When the "Dividend Transaction Statement" report has been disabled
  Then I should see a "Dividend Summary" report table with all data missing
  Then I should see the "Dividend Details" report table with Data Unavailable messaging