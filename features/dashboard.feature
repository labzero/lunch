Feature: Visiting the Dashboard
  As a user
  I want to use visit the dashboard for the FHLB Member Portal
  In order to find information

Background:
  Given I am logged in

  @smoke
  Scenario: Visit dashboard
    When I visit the dashboard
    Then I should see dashboard modules

  Scenario: See dashboard contacts
    When I visit the dashboard
    Then I should see 3 contacts

  @smoke
  Scenario: See Your Account module
    When I visit the dashboard
    Then I should see the Your Account table breakdown
      And I should see an "borrowing capacity gauge" in the Account module
      And I should see a "financing availability gauge" in the Account module

  @smoke
  Scenario: See dashboard market overview graph
    When I visit the dashboard
    Then I should see a market overview graph

  @data-unavailable @jira-mem-408
  Scenario: Data for Aggregate 30 Day Terms module is temporarily unavailable
    Given I visit the dashboard
    When there is no data for "Aggregate 30 Day Terms"
    Then the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state
