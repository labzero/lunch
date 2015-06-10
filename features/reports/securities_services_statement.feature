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

@smoke @jira-mem-536
Scenario: Member chooses the current month to date preset on Securities Services Monthly Statement
  Given I am on the "Securities Services Monthly Statement" report page
  When I click the datepicker field
  And I choose the "custom date" preset in the datepicker
  And I select the 14th of "last month" in the single datepicker calendar
  And I click the datepicker apply button
  Then I should see a "Securities Services Monthly Statement" for the 14th of the last month

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