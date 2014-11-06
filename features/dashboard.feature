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