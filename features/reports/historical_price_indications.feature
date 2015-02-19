Feature: Visiting the Historical Price Indications Report Page
  As a user
  I want to use visit the historical price indications report page for the FHLB Member Portal
  In order to view historic price indications (rates)

Background:
  Given I am logged in

@smoke
Scenario: Visit historical price indications from header link
  Given I visit the dashboard
  When I select "Historical" from the reports dropdown
  Then I should see "Historical Price Indications"
  And I should see a report table with multiple data rows

Scenario: Defaults to Standard Collateral Program with fixed-rates
  Given I visit the dashboard
  When I select "Historical" from the reports dropdown
  Then I should see "Standard Credit Program"
  And I should see "Fixed Rate Credit (FRC)"

@smoke
Scenario: Member sorts the historical price indications report by date
  Given I am on the Historical Price Indications page
  When I click the Date column heading
  Then I should see the "Date" column values in "ascending" order
  And I click the Date column heading
  Then I should see the "Date" column values in "descending" order