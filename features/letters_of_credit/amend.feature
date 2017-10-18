@flip-on-letters-of-credit
@flip-on-letters-of-credit-amend
Feature: Amending an existing Letter of Credit
  As a user
  I want to amend a Letter of Credit request
  In order to manage the credit options available to my bank

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-2497
  Scenario Outline: Accessing the Letter of Credit `Amend` link on the Manage Letters of Credit page
    Given I am logged in as a "<user_type>"
    When I visit the Manage Letters of Credit page
    Then I <permission> see the link to amend an existing letter of credit
  Examples:
    | user_type                | permission |
    | quick-advance signer     | should     |
    | intranet user            | should     |
    | quick-advance non-signer | should not |

  @jira-mem-2497
  Scenario: Clicking the Amend link to access the Request Letter of Credit Amendment page
    Given I visit the dashboard
    When I click on the letters of credit link in the header
    When I click on the manage letters of credit link in the header
    Then I should be on the Manage Letters of Credit page
    When I click the amend link on a Letter of Credit row
    Then I should be on the Request Letter of Credit Amendment page

  @jira-mem-2497
  Scenario: The Preview Request button state
    When I visit the Request Letter of Credit Amendment page
    Then I should see the Preview Request button in its disabled state
    When I enter 1234 in the letter of credit amended_amount field
    Then I should see the Preview Request button in its enabled state

  @jira-mem-2497
  Scenario: The Preview Request button state
    When I visit the Request Letter of Credit Amendment page
    Then I should see the Preview Request button in its disabled state
    When I enter a valid business day after the expiration date in the datepicker
    Then I should see the Preview Request button in its enabled state

  @jira-mem-2497
  Scenario: Member enters an Amended Credit Amount less than the original Letter of Credit amount
    When I visit the Request Letter of Credit Amendment page
    And I enter 14749999 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should be on the Request Letter of Credit Amendment page
    Then I should see the "amended amount less than original amount" form error

  @jira-mem-2497
  Scenario: Member enters an Amended Credit Amount greater than the original Letter of Credit amount
    When I visit the Request Letter of Credit Amendment page
    And I enter 14750001 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should be on the Preview Letter of Credit Amendment page


  @jira-mem-2497
  Scenario: Member selects the maximum expiration date
    When I visit the Request Letter of Credit Amendment page
    And I choose the last possible date for the amended expiration date
    And I enter 14750001 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should be on the Preview Letter of Credit Amendment page

  @jira-mem-2497
  Scenario: Amended amount input field on Request Letter of Credit Amendment page does not allow letters or symbols
    Given I visit the Request Letter of Credit Amendment page
    When I try to enter "asdf#*@&!asdf" in the letter of credit amended_amount field
    Then the letter of credit amended_amount field should be blank

  @jira-mem-2497
  Scenario: Letter of credit amount input field adds commas to input field
    Given I visit the Request Letter of Credit Amendment page
    When I enter 7894561235 in the letter of credit amended_amount field
    Then the letter of credit amended_amount field should show "7,894,561,235"

  @jira-mem-2497
  Scenario: Member enters an amount that exceeds their Remaining Standard Borrowing Capacity
    Given I visit the Request Letter of Credit Amendment page
    And I enter 100000000 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should see the "exceeds borrowing capacity of 95460000" form error

  @jira-mem-2497
  Scenario: Member enters an amount that exceeds their Remaining Standard Borrowing Capacity
    Given I visit the Request Letter of Credit Amendment page
    And I enter 150000000 in the letter of credit amended_amount field
    When I click the Preview Request button
    Then I should see the "exceeds financing availability of 149,603,250" form error

  @jira-mem-2635
  Scenario: Member attempts to amend a letter of credit that is not amendable online
    Given I visit the Manage Letters of Credit page
    When I click on the amend link for a letter of credit that is not amendable online
    Then I should see the "not amendable online" form error