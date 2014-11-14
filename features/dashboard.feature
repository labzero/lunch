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

  Scenario: See Your Account module
    When I visit the dashboard
    Then I should see the Your Account table breakdown
    And I should see the Anticipated Activity graph
    And I should see a pledged collateral gauge
    And I should see a total securities gauge
    And I should see an effective borrwoing capacity gauge

  Scenario: See dashboard market overview graph
    When I visit the dashboard
    Then I should see a market overview graph
