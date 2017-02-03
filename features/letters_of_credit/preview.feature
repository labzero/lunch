@flip-on-letters-of-credit
Feature: Previewing a New Letter of Credit Request
  As a user
  I want to see a preview of my request for a New Letter of Credit
  In order to ensure it contains the correct information before making the request

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-1972
  Scenario: Viewing the New Letter of Request Preview
    Given I visit the Request Letter of Credit page
    And I enter 1234567 in the letter of credit amount field
    When I click the Preview Request button
    Then I should be on the Preview Letter of Credit Request page
    And I should see summary data for the letter of credit
    And I should see that the amount in the preview is 1234567

  @jira-mem-1972
  Scenario Outline: Viewing the SecureID fields
    Given I am logged in as a "<user_type>"
    When I visit the Preview Letter of Credit page
    Then I <permission> see the SecureID fields
  Examples:
    | user_type                | permission |
    | quick-advance signer     | should     |
    | intranet user            | should not |

  @jira-mem-1972
  Scenario: Users are informed if they enter an invalid pin or token
    Given I visit the Preview Letter of Credit page
    When I enter "12ab" for my SecurID pin
    And I enter my SecurID token
    And I click the Authorize Request button
    Then I should see SecurID errors on the Letter of Credit preview page
    When I enter my SecurID pin
    And I enter "12ab34" for my SecurID token
    And I click the Authorize Request button
    Then I should see SecurID errors on the Letter of Credit preview page
