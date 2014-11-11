Feature: Visiting the Dashboard
  As a user
  I want to use visit the dashboard for the FHLB Member Portal
  In order to find information

  Scenario: Visit dashboard
    When I visit the dashboard
    Then I should see dashboard modules

  Scenario: See dashboard contacts
    When I visit the dashboard
    Then I should see 2 contacts

  Scenario: See dashboard quick advance module
    When I visit the dashboard
    Then I should see a dollar amount field
    And I should see an advance rate.

  Scenario: See dashboard Your Account breakdown
    When I visit the dashboard
    Then I should see "Your Account"
    And I should see "Sta Balance"
    And I should see "Credit Outstanding"
    And I should see "Collateral Market Value"
    And I should see "Collateral borrowing capacity"