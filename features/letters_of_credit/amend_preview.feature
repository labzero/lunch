@flip-on-letters-of-credit
Feature: Previewing a Letter of Credit Amendment Request
  As a user
  I want to see a preview of my request for a Letter of Credit Amendment
  In order to ensure it contains the correct information before making the request

  Background:
    Given I am logged in as a "quick-advance signer"

  @flip-on-letters-of-credit-amend
  Scenario: Viewing the Letter of Credit Amendment Preview
    Given I visit the Request Letter of Credit Amendment page
    And I enter 14750001 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should be on the Preview Letter of Credit Amendment page
    And I should see summary data for the letter of credit on the letter of credit amendment page
    And I should see that the amount in the preview amendment request is 14750001

  Scenario Outline: Viewing the SecureID fields
    Given I am logged in as a "<user_type>"
    When I visit the Preview Letter of Credit Amendment page
    Then I <permission> see the SecureID fields
    Examples:
      | user_type                | permission |
      | quick-advance signer     | should     |
      | intranet user            | should not |

  Scenario: Users are informed if they enter an invalid pin or token
    Given I visit the Preview Letter of Credit Amendment page
    When I enter "12ab" for my SecurID pin
    And I enter my SecurID token
    And I click the Authorize Request button
    Then I should see SecurID errors on the Letter of Credit Amendment preview page
    When I enter my SecurID pin
    And I enter "12ab34" for my SecurID token
    And I click the Authorize Request button
    Then I should see SecurID errors on the Letter of Credit Amendment preview page