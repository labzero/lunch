Feature: Visiting the Reports Summary Page
  As a user
  I want to use visit the reports summary page for the FHLB Member Portal
  In order to view reports

@smoke
Scenario: Visit reports summary page from header link
  Given I visit the dashboard
  When I click on the reports link in the header
  Then I should see "Report" as the report page's main title
  And I should see a table of "Credit" reports
  And I should see a table of "Collateral" reports
  And I should see a table of "Capital Stock" reports

Scenario: Member sees reports dropdown
  Given I visit the dashboard
  And I don't see the reports dropdown
  When I hover on the reports link in the header
  Then I should see the reports dropdown

@smoke
Scenario: Member sees Capital Stock Activity Statement
  Given I visit the dashboard
  When I select "Capital Stock Activity Statement" from the reports dropdown
  Then I should see report summary data
    And I should see a report table with multiple data rows

Scenario: Member sorts the Capital Stock Activity Statement by date
  Given I am on the Capital Stock Activity Statement page
    And I should see the "Date" column values in "ascending" order
  When I click the Date column heading
  Then I should see the "Date" column values in "descending" order


Scenario: Member sorts the Capital Stock Activity Statement
  Given I am on the Capital Stock Activity Statement page
  When I click the Certificate Sequence column heading
  Then I should see the "Certificate Sequence" column values in "ascending" order
  And I click the Certificate Sequence column heading
  Then I should see the "Certificate Sequence" column values in "descending" order

Scenario: Member sees date picker when interacting with date field
  Given I am on the Capital Stock Activity Statement page
  When I click the datepicker field
  Then I should see the datepicker

Scenario: Member chooses the current month to date preset on Capital Stock Activity Statement
  Given I am on the Capital Stock Activity Statement page
  And I click the datepicker field
  When I choose the month to date preset in the datepicker
  Then I should see no calendar
  When I click the datepicker apply button
  Then I should see a Capital Stock Activity Statement for the current month to date

Scenario: Member chooses the last month preset on Capital Stock Activity Statement
  Given I am on the Capital Stock Activity Statement page
  And I click the datepicker field
  When I choose the last month preset in the datepicker
  Then I should see no calendar
  When I click the datepicker apply button
  Then I should see a Capital Stock Activity Statement for the last month

Scenario: Member chooses a custom date range on Capital Stock Activity Statement
  Given I am on the Capital Stock Activity Statement page
  And I click the datepicker field
  When I choose the custom date range in the datepicker
  Then I should see two calendars
  When I select the 15th of this month in the left calendar
  And I select the 20th of this month in the right calendar
  And I click the datepicker apply button
  Then I should see a Capital Stock Activity Statement for the 15th through the 20th of this month


