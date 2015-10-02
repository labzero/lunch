@jira-mem-69
Feature: Visiting the Advances Detail Report Page
  As a user
  I want to use visit the advances detail report page for the FHLB Member Portal
  In order to view the details of my current and past advances

Background:
  Given I am logged in

@smoke @jira-mem-405
Scenario: Visit advances details page from header link
  Given I visit the dashboard
  When I select "Advances" from the reports dropdown
  Then I should see report summary data
  And I should see a report header
  And I should see a report table with multiple data rows

# NOTE: If this is changed to a smoke test and run against production data, "as_of_date" as returned by MAPI could be either today or yesterday depending on when the test is run
@jira-mem-405
Scenario: Defaults to current advances details
  Given I visit the dashboard
  When I select "Advances" from the reports dropdown
  Then I should see advances details for today

@jira-mem-405
Scenario: Viewing historic advances details
  Given I am on the "Advances Detail" report page
  When I click the datepicker field
  And I choose the "custom date" preset in the datepicker
  And I select the 14th of "last month" in the single datepicker calendar
  And I click the datepicker apply button
  Then I should see advances details for the 14th of last month

@jira-mem-405
Scenario: Viewing the details of a given advance
  Given I am on the "Advances Detail" report page
  When I click on the view cell for the first advance
  Then I should see the detailed view for the first advance
  When I click on the hide link for the first advance
  Then I should not see the detailed view for the first advance

@smoke @jira-mem-405
Scenario: Member sorts the advances details report by trade date
  Given I am on the "Advances Detail" report page
  When I click the "Trade Date" column heading
  Then I should see the "Trade Date" column values in "ascending" order
  And I click the "Trade Date" column heading
  Then I should see the "Trade Date" column values in "descending" order

@jira-mem-324 @jira-mem-505
Scenario: Member can't select a date in the future
  Given I am on the "Advances Detail" report page
  When I click the datepicker field
  Then I should not see available dates after today

@jira-mem-630
Scenario: Entering text in the datepicker input field
  Given I am on the "Advances Detail" report page
  When I click the datepicker field
  And I write a date from one month ago in the datepicker start input field
  And I click the datepicker apply button
  Then I should see a "Advances Detail" report as of 1 month ago

@jira-mem-890
Scenario: Member enters a date occurring before the minimum allowed date
  Given I am on the "Advances Detail" report page
  When I click the datepicker field
  And I write "1/10/2013" in the datepicker start input field
  And I click the datepicker apply button
  Then I should see a "Advances Detail" report as of 18 months ago

@jira-mem-890
Scenario: Member enters a date occurring after the maximum allowed date
  Given I am on the "Advances Detail" report page
  When I click the datepicker field
  And I write tomorrow's date in the datepicker start input field
  And I click the datepicker apply button
  Then I should see a "Advances Detail" report as of today

@data-unavailable @jira-mem-283 @jira-mem-1053
Scenario: No data is available to show in the Advances Detail Report
  Given I am on the "Advances Detail" report page
  When the "Advances Detail" table has no data
  Then I should see an empty report table with No Records messaging

@data-unavailable @jira-mem-282 @jira-mem-1053
Scenario: The Advances Detail Report has been disabled
  Given I am on the "Advances Detail" report page
  When the "Advances Detail" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging

@jira-mem-415 @jira-mem-543
Scenario: Member interacts with the 'report loading' flyout when downloading a PDF of the Advance Detail report
  Given I am on the "Advances Detail" report page
  When I request a PDF
  Then I should see the report download flyout
  When I cancel the report download from the flyout
  Then I should not see the report download flyout

@jira-mem-415 @jira-mem-543
Scenario: Member interacts with the 'report loading' flyout when downloading an XLSX of the Advance Detail report
  Given I am on the "Advances Detail" report page
  When I request an XLSX
  Then I should see the report download flyout
  When I cancel the report download from the flyout
  Then I should not see the report download flyout

@resque-backed @smoke @jira-mem-415 @jira-mem-543
Scenario: Member downloads a PDF of the Advances Detail report
  Given I am on the "Advances Detail" report page
  When I request a PDF
  Then I should begin downloading a file

@resque-backed @smoke @jira-mem-538 @jira-mem-543
Scenario: Member downloads an XLSX of the Advances Detail report
  Given I am on the "Advances Detail" report page
  When I request an XLSX
  Then I should begin downloading a file
