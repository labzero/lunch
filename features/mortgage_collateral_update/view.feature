@flip-on-mortgages
Feature: Viewing the details of an existing Mortgage Collateral Update
  As a user
  I want to view the details of an existing Mortgage Collateral Update
  In order to access information and print reports

  Background:
    Given I am logged in as a "collateral signer"

  @jira-mem-2579
  Scenario: Navigating to the detail view of an existing MCU transaction
    Given I am on the manage mortgage collateral updates page
    When I click on the View Details link in the first row of the MCU Recent Requests table
    Then I should be on the Mortgage Collateral Update Status page
    And I should see a list of transaction details for the transaction that was in the first row of the MCU Recent Request table
    When I click on the Manage MCUS button
    Then I should be on the Manage Mortgage Collateral Updates page