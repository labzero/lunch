@jira-mem-69
Feature: Visiting the Historical Price Indications Report Page
  As a user
  I want to use visit the historical price indications report page for the FHLB Member Portal
  In order to view historic price indications (rates)

Background:
  Given I am logged in

@smoke @jira-mem-311
Scenario: Visit historical price indications from header link
  Given I visit the dashboard
  When I select "Historical" from the reports dropdown
  Then I should see "Historical Price Indications"
  And I should see a report table with multiple data rows

@jira-mem-311
Scenario: Defaults to Standard Collateral Program FRC
  Given I am on the "Historical Price Indications" report page
  Then I should see "Standard Credit Program"
  And I should see "Fixed Rate Credit (FRC)"

@jira-mem-358
Scenario: Choosing an SBC credit program should select the default credit type if the current credit_type is not available in SBC programs.
  Given I am on the "Historical Price Indications" report page
  And I select "Adjustable Rate Credit (ARC) Daily Prime" from the credit type selector
  When I select "Securities-Backed Credit" from the collateral type selector
  Then I should see "Fixed Rate Credit (FRC)"

@smoke @jira-mem-318 @jira-mem-402 @jira-mem-358
Scenario Outline: Choosing different historic price indication reports
  Given I am on the "Historical Price Indications" report page
  When I select "<collateral_type>" from the <collateral_selector> type selector
  When I select "<credit_type>" from the <credit_selector> type selector
  Then I should see "<credit_type>"
  And I should see "<table_heading>"
  Examples:
  | collateral_type          | collateral_selector | credit_type                                | credit_selector | table_heading                |
  | Standard Credit Program  | collateral          | Adjustable Rate Credit (ARC) 1 month LIBOR | credit          | 1 mo LIBOR                   |
  | Standard Credit Program  | collateral          | Adjustable Rate Credit (ARC) 3 month LIBOR | credit          | 3 mo LIBOR                   |
  | Standard Credit Program  | collateral          | Adjustable Rate Credit (ARC) 6 month LIBOR | credit          | 6 mo LIBOR                   |
  | Standard Credit Program  | collateral          | Adjustable Rate Credit (ARC) Daily Prime   | credit          | Daily Prime                  |
  | Standard Credit Program  | collateral          | Variable Rate Credit (VRC)                 | credit          | Variable Rate Credit (VRC)   |
  | Securities-Backed Credit | collateral          | Adjustable Rate Credit (ARC) 1 month LIBOR | credit          | 1 mo LIBOR                   |
  | Securities-Backed Credit | collateral          | Adjustable Rate Credit (ARC) 3 month LIBOR | credit          | 3 mo LIBOR                   |
  | Securities-Backed Credit | collateral          | Adjustable Rate Credit (ARC) 6 month LIBOR | credit          | 6 mo LIBOR                   |
  | Securities-Backed Credit | collateral          | Variable Rate Credit (VRC)                 | credit          | Variable Rate Credit (VRC)   |

@jira-mem-359
Scenario: Custom datepicker options
  Given I am on the "Historical Price Indications" report page
  When I click the datepicker field
  Then I should see "Year to date"
  And I should see "Last year"

@jira-mem-359
Scenario: Choosing `Last year` as a datepicker option
  Given I am on the "Historical Price Indications" report page
  When I click the datepicker field
  And I choose the "last year preset" in the datepicker
  And I click the datepicker apply button
  Then I should see a report with dates for last year

@data-unavailable @jira-mem-283
Scenario: No data is available to show in the Historical Price Indications report
  Given I am on the "Historical Price Indications" report page
  When the "Historical Price Indications" table has no data
  Then I should see an empty report table with Data Unavailable messaging

@data-unavailable @jira-mem-282
Scenario: The Historical Price Indications report has been disabled
  Given I am on the "Historical Price Indications" report page
  When the "Historical Price Indications" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging
