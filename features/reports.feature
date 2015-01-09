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


