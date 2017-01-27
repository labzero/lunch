@flip-on-letters-of-credit
Feature: Requesting a New Letter of Credit
  As a user
  I want to request a New Letter of Credit
  In order to extend the credit options available to my bank

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-1970
  Scenario Outline: Accessing the New Letter of Credit page
    Given I am logged in as a "<user_type>"
    When I visit the dashboard
    Then I <permission> see the letters of credit dropdown for Request Letter of Credit
    When I visit the Manage Letters of Credit page
    Then I <permission> see the button to request a new letter of credit
  Examples:
    | user_type                | permission |
    | quick-advance signer     | should     |
    | intranet user            | should     |
    | quick-advance non-signer | should not |

  @jira-mem-1970
  Scenario: Visit New Letter of Credit from the header
    Given I visit the dashboard
    When I click on the letters of credit link in the header
    And I click on the new letter of credit link in the header
    Then I should be on the New Letter of Credit Request page