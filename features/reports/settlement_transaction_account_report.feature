@jira-mem-69
Feature: Visiting the Settlement Transaction Account Report Page
  As a user
  I want to use visit the settlement transaction report page for the FHLB Member Portal
  In order to view settlement transaction account credits, debits and rates

Background:
  Given I am logged in

@smoke
Scenario: Member sees Settlement Transaction Account Statement in the reports dropdown
Given I visit the dashboard
When I hover on the reports link in the header
Then I should see "Settlement/Transaction Account (STA)" in the reports dropdown

@smoke
Scenario: Member sees Settlement Transaction Account Statement
Given I am on the "Settlement Transaction Account Statement" report page
Then I should see report summary data
And I should see a report header
And I should see a report table with multiple data rows

Scenario: Member chooses a custom date range on the Settlement Transaction Account Statement
Given I am on the "Settlement Transaction Account Statement" report page
And I click the datepicker field
When I choose the "custom date range" preset in the datepicker
Then I should see two calendars
When I select the 1st of "last month" in the left calendar
And I select the 20th of "last month" in the right calendar
And I click the datepicker apply button
Then I should see a "Settlement Transaction Account Statement" with data for dates between the 1st through the 20th of last month

@jira-mem-890
Scenario: Member enters a date occurring before the minimum allowed date
Given I am on the "Settlement Transaction Account Statement" report page
When I click the datepicker field
And I write "1/10/2014" in the datepicker start input field
And I write today's date in the datepicker end input field
And I click the datepicker apply button
Then I should see a "Settlement Transaction Account Statement" starting 6 months ago and ending today

@jira-mem-890
Scenario: Member enters a date occurring after the maximum allowed date
Given I am on the "Settlement Transaction Account Statement" report page
When I click the datepicker field
And I write a date from one month ago in the datepicker start input field
And I write tomorrow's date in the datepicker end input field
And I click the datepicker apply button
Then I should see a "Settlement Transaction Account Statement" starting 1 month ago and ending today

@jira-mem-247, @jira-mem-503
Scenario: Member filters the Settlement Transaction Account Statement
Given I am on the "Settlement Transaction Account Statement" report page
And I am showing Settlement Transaction Account activities for the last 3 months
When I filter the report by "Credits"
Then I should only see "Credit" rows in the Settlement Transaction Account Statement table
When I filter the report by "Debits"
Then I should only see "Debit" rows in the Settlement Transaction Account Statement table
When I filter the report by "Daily Balances"
Then I should only see "Balance ($)" rows in the Settlement Transaction Account Statement table

@data-unavailable @jira-mem-283 @jira-mem-1053
Scenario: No data is available to show in the Settlement Transaction Account Statement
  Given I am on the "Settlement Transaction Account Statement" report page
  When the "Settlement Transaction Account" table has no data
  Then I should see an empty report table with No Records messaging

@data-unavailable @jira-mem-282 @jira-mem-1053
Scenario: The Settlement Transaction Account Statement has been disabled
  Given I am on the "Settlement Transaction Account Statement" report page
  When the "Settlement Transaction Account" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging

@jira-mem-812 @resque-backed @smoke
Scenario: Member downloads a PDF of the Settlement Transaction Account Statement
  Given I am on the "Settlement Transaction Account Statement" report page
  When I request a PDF
  Then I should begin downloading a file

@jira-mem-919
Scenario: The datepicker handles two-digit years and prohibited characters
  Given I am on the "Settlement Transaction Account Statement" report page
  When I click the datepicker field
  Then I am able to enter two-digit years in the datepicker inputs
  And I am not able to enter prohibited characters in the datepicker inputs
