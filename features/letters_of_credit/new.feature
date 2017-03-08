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

  @jira-mem-1972
  Scenario: The Preview Request button state
    When I visit the Request Letter of Credit page
    Then I should see the Preview Request button in its disabled state
    When I enter 1234 in the letter of credit amount field
    Then I should see the Preview Request button in its enabled state

  @jira-mem-2149 @local-only
  Scenario: Member selects an expiration date that occurs more than 15 years after the issue date
    When I visit the Request Letter of Credit page
    And I have a maximum borrowing term of 500 months
    And I choose the last possible date for the expiration date
    And I choose the first possible date for the issue date
    And I enter 1234567 in the letter of credit amount field
    When I click the Preview Request button
    Then I should see the "expiration date invalid" form error

  @jira-mem-1972
  Scenario: Member selects an expiration date that occurs before the issue date
    When I visit the Request Letter of Credit page
    And I choose the first possible date for the expiration date
    And I choose the last possible date for the issue date
    And I enter 1234 in the letter of credit amount field
    When I click the Preview Request button
    Then I should see the "expiration date before issue date" form error

  @jira-mem-2150 @local-only
  Scenario: Member selects an expiration date that exceeds their maximum term limit for borrowing
    Given I visit the Request Letter of Credit page
    And I have a maximum borrowing term of 12 months
    And I choose the last possible date for the expiration date
    And I enter 1234567 in the letter of credit amount field
    When I click the Preview Request button
    Then I should see the "expiration date exceeds max term of 12 months" form error

  Scenario: Letter of credit amount input field does not allow letters or symbols
    Given I visit the Request Letter of Credit page
    When I try to enter "asdf#*@&!asdf" in the letter of credit amount field
    Then the letter of credit amount field should be blank

  Scenario: Letter of credit amount input field adds commas to input field
    Given I visit the Request Letter of Credit page
    When I enter 7894561235 in the letter of credit amount field
    Then the letter of credit amount field should show "7,894,561,235"

  @jira-mem-2148
  Scenario: Member enters an amount that exceeds their Remaining Standard Borrowing Capacity
    Given I visit the Request Letter of Credit page
    And I have a borrowing capacity of 1000
    And I enter 1234 in the letter of credit amount field
    When I click the Preview Request button
    Then I should see the "exceeds borrowing capacity by 1000" form error
