@jira-mem-69
Feature: Visiting the Settlement Transaction Account Report Page
  As a user
  I want to use visit the settlement transaction report page for the FHLB Member Portal
  In order to view settlement transaction account credits, debits and rates

Background:
  Given I am logged in

@smoke
Scenario: Member sees Settlement Transaction Account Statement
Given I visit the dashboard
When I select "Settlement/Transaction Account (STA)" from the reports dropdown
Then I should see report summary data
And I should see a report table with multiple data rows

Scenario: Member chooses a custom date range on the Settlement Transaction Account Statement
Given I am on the Settlement Transaction Account Statement page
And I click the datepicker field
When I choose the "custom date range" in the datepicker
Then I should see two calendars
When I select the 1st of "last month" in the left calendar
And I select the 20th of "last month" in the right calendar
And I click the datepicker apply button
Then I should see a "Settlement Transaction Account Statement" with data for dates between the 1st through the 20th of last month

@jira-mem-247, @jira-mem-503
Scenario: Member filters the Settlement Transaction Account Statement
Given I am on the Settlement Transaction Account Statement page
And I am showing Settlement Transaction Account activities for 2014
When I filter the Settlement Transaction Account Statement by "Credits"
Then I should only see "Credit" rows in the Settlement Transaction Account Statement table
When I filter the Settlement Transaction Account Statement by "Debits"
Then I should only see "Debit" rows in the Settlement Transaction Account Statement table
When I filter the Settlement Transaction Account Statement by "Daily Balances"
Then I should only see "Balance ($)" rows in the Settlement Transaction Account Statement table

@data-unavailable @jira-mem-283
Scenario: No data is available to show in the Settlement Transaction Account Statement
  Given I am on the Settlement Transaction Account Statement page
  When the "Settlement Transaction Account" table has no data
  Then I should see an empty report table with Data Unavailable messaging

@data-unavailable @jira-mem-282
Scenario: The Settlement Transaction Account Statement has been disabled
  Given I am on the Settlement Transaction Account Statement page
  When the "Settlement Transaction Account" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging