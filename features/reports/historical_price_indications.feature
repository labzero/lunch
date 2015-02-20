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
Scenario: Choosing Standard, 1 month LIBOR rate
  Given I am on the Historical Price Indications page
  When I select "Adjustable Rate Credit (ARC) 1 month LIBOR" from the credit type selector
  Then I should see "Adjustable Rate Credit (ARC) 1 month LIBOR"
  And I should see "1 mo LIBOR"

@smoke
Scenario Outline: Choosing different historic price indication reports
  Given I am on the Historical Price Indications page
  When I select "<credit_type>" from the <selector> type selector
  Then I should see "<credit_type>"
  And I should see "<table_heading>"
  Examples:
  | credit_type                                | selector | table_heading     |
  | Adjustable Rate Credit (ARC) 1 month LIBOR | credit   | 1 mo LIBOR        |
  | Adjustable Rate Credit (ARC) 3 month LIBOR | credit   | 3 mo LIBOR        |
  | Adjustable Rate Credit (ARC) 6 month LIBOR | credit   | 6 mo LIBOR        |
  | Adjustable Rate Credit (ARC) Daily Prime   | credit   | Daily Prime LIBOR |
