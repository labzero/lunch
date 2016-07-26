@jira-mem-69 @flip-on-report-securities-transaction
Feature: Visiting the Securities Transactions Report Page
  As a user
  I want to use visit the interest rate resets report page for the FHLB Member Portal
  In order to view securities transactions

Background:
  Given I am logged in

@smoke @jira-mem-410
Scenario: Visit securities transactions from header link
  Given I visit the dashboard
  When I select "Securities Transactions" from the reports dropdown
  Then I should see "Securities Transactions"
  And I should see a report header
  And I should see a report table with multiple data rows

@smoke @jira-mem-410
Scenario: Visiting the Securities Transactions Report Page
  Given I am on the "Securities Transactions" report page
  Then I should see "Total Net Amount"
  And I should see Securities Transactions report

# NOTE: This is for fake data only, will change with MAPI
@smoke @jira-mem-410
Scenario: Visiting the Securities Transactions Report Page with new securities transaction
  Given I am on the "Securities Transactions" report page
  Then I should see a security that is indicated as a new transaction

@resque-backed @smoke @jira-mem-814
Scenario: Member downloads a PDF of the Advances Detail report
  Given I am on the "Securities Transactions" report page
  When I request a PDF
  Then I should begin downloading a file

@resque-backed @smoke @jira-mem-815
Scenario: Member downloads an XLSX of the Securities Transactions report
  Given I am on the "Securities Transactions" report page
  When I request an XLSX
  Then I should begin downloading a file

@data-unavailable @jira-mem-410
Scenario: Visiting the Securities Transactions Report Page before the desk is closed
  Given I am on the "Securities Transactions" report page
  Then I should see a preliminary securities transaction report

@data-unavailable @smoke @jira-mem-410 @jira-mem-1053
Scenario: Securities Transactions Report has been disabled
  Given I am on the "Securities Transactions" report page
  When the "Securities Transactions" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging

@jira-1086
Scenario: Securities Transactions Report has no records
  Given I am on the "Securities Transactions" report page
  When I click the datepicker field
  And I write "12/25/2015" in the datepicker start input field
  And I click the datepicker apply button
  Then I should see an empty report table with No Records messaging

@jira-1086
Scenario: Securities Transactions Report is preliminary
  Given I am on the "Securities Transactions" report page
  When I click the datepicker field
  And I write "12/1/2015" in the datepicker start input field
  And I click the datepicker apply button
  Then I should see a preliminary securities transaction report

@jira-mem-919
Scenario: The datepicker handles two-digit years and prohibited characters
  Given I am on the "Securities Transactions" report page
  When I click the datepicker field
  Then I am able to enter two-digit years in the datepicker input
  And I am not able to enter prohibited characters in the datepicker input
