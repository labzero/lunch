@flip-on-mortgages
Feature: Managing Mortgage Collateral Updates
  As a user
  I want to Manage Mortgage Collateral Updates
  In order to extend the credit options available to my bank

  Background:
    Given I am logged in as a "collateral signer"

  @jira-mem-2579
  Scenario: Visiting the Manage Mortgage Collateral Updates (MCU) page
    Given I visit the dashboard
    When I click on the mortgages link in the header
    And I click on the manage mortgage collateral updates link in the header
    Then I should be on the Manage Mortgage Collateral Updates page