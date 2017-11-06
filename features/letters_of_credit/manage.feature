@flip-on-letters-of-credit
Feature: Managing Letters of Credit
  As a user
  I want to visit the Manage Letters of Credit page
  In order to manage my letters of credit

  Background:
    Given I am logged in

  @smoke @jira-mem-1969
  Scenario: Visit Manage Letters of Credit from the header
    Given I visit the dashboard
    When I click on the letters of credit link in the header
    When I click on the manage letters of credit link in the header
    Then I should be on the Manage Letters of Credit page

  @jira-mem-2152
  Scenario: Member institutions ineligible for letters of credit see a special error message
    Given I am signed in as a Chaste Manhattan signer
    And I visit the Request Letter of Credit page
    Then I should see that my bank is not authorized to request a Letter of Credit


  @data-unavailable @jira-mem-2511
  Scenario: The Manage Letters of Credit page has been disabled
    Given I visit the Manage Letters of Credit page
    When the "Manage Letters of Credit" page has been disabled
    Then I should see an empty data table with "Data Currently Disabled" messaging