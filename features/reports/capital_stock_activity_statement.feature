@jira-mem-69
Feature: Visiting the Capital Stock Activity Statement Page
  As a user
  I want to use visit the captial stock activity statement page for the FHLB Member Portal
  In order to view my capital stock activity for various dates

Background:
  Given I am logged in

@smoke
Scenario: Member sees Capital Stock Activity Statement
  Given I visit the dashboard
  When I select "Capital Stock Activity Statement" from the reports dropdown
  Then I should see report summary data
  And I should see a report table with multiple data rows

@smoke @jira-mem-353
Scenario: Member sorts the Capital Stock Activity Statement by date
  Given I am on the "Capital Stock Activity Statement" report page
  And I should see the "Issue Date" column values in "ascending" order
  When I click the "Issue Date" column heading
  Then I should see the "Issue Date" column values in "descending" order

@smoke
Scenario: Member sorts the Capital Stock Activity Statement by certificate sequence
  Given I am on the "Capital Stock Activity Statement" report page
  When I click the "Certificate Sequence" column heading
  Then I should see the "Certificate Sequence" column values in "ascending" order
  And I click the "Certificate Sequence" column heading
  Then I should see the "Certificate Sequence" column values in "descending" order

@smoke @jira-mem-353
Scenario: Member sorts the Capital Stock Activity Statement by outstanding shares
  Given I am on the "Capital Stock Activity Statement" report page
  When I click the "Outstanding Shares" column heading
  Then I should see the "Outstanding Shares" column values in "ascending" order
  And I click the "Outstanding Shares" column heading
  Then I should see the "Outstanding Shares" column values in "descending" order

Scenario: Member sees date picker when interacting with date field
  Given I am on the "Capital Stock Activity Statement" report page
  When I click the datepicker field
  Then I should see the datepicker

@smoke
Scenario: Member chooses the current month to date preset on Capital Stock Activity Statement
  Given I am on the "Capital Stock Activity Statement" report page
  And I click the datepicker field
  When I choose the "month to date" preset in the datepicker
  Then I should see no calendar
  When I click the datepicker apply button
  Then I should see a "Capital Stock Activity Statement" for the current month to date

@smoke
Scenario: Member chooses the last month preset on Capital Stock Activity Statement
  Given I am on the "Capital Stock Activity Statement" report page
  And I click the datepicker field
  When I choose the "last month" preset in the datepicker
  Then I should see no calendar
  When I click the datepicker apply button
  Then I should see a "Capital Stock Activity Statement" for the last month

@smoke
Scenario: Member chooses a custom date range on Capital Stock Activity Statement
  Given I am on the "Capital Stock Activity Statement" report page
  And I click the datepicker field
  When I choose the "custom date range" preset in the datepicker
  Then I should see two calendars
  When I select the 15th of "last month" in the left calendar
  And I select the 20th of "last month" in the right calendar
  And I click the datepicker apply button
  Then I should see a "Capital Stock Activity Statement" for the 15th through the 20th of last month

@jira-mem-630
Scenario: Entering text in the datepicker input fields
  Given I am on the "Capital Stock Activity Statement" report page
  When I click the datepicker field
  And I write a date from one month ago in the datepicker start input field
  And I write today's date in the datepicker end input field
  And I click the datepicker apply button
  Then I should see a "Capital Stock Activity Statement" starting one month ago and ending today

@data-unavailable @jira-mem-283
Scenario: No data is available to show in the Capital Stock Activity Statement
  Given I am on the "Capital Stock Activity Statement" report page
  When the "Capital Stock Activity" table has no data
  Then I should see an empty report table with Data Unavailable messaging

@data-unavailable @jira-mem-282
Scenario: The Capital Stock Activity Statement has been disabled
  Given I am on the "Capital Stock Activity Statement" report page
  When the "Capital Stock Activity" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging