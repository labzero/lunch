@flip-on-letters-of-credit
@flip-on-letters-of-credit-beneficiary
Feature: Requesting an Add Beneficiary
  As a user
  I want to request a new Beneficiary
  In order to request a letter of credit with this beneficiary

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-2551
  Scenario: Visit an Add Beneficiary from New Letter of Credit
    Given I visit the dashboard
    When I click on the letters of credit link in the header
    And I click on the new letter of credit link in the header
    And I should be on the New Letter of Credit Request page
    When I click on Add Beneficiary link
    Then I should be on the Add Beneficiary Request page