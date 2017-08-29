@flip-on-letters-of-credit

Feature: Amending an existing Letter of Credit
  As a user
  I want to amend a Letter of Credit request
  In order to manage the credit options available to my bank

  Background:
    Given I am logged in as a "quick-advance signer"

  @flip-on-letters-of-credit-amend
  Scenario: Visit Request Letter of Credit Amendment page from the Manage Letters of Credit page
    Given I visit the dashboard
    When I click on the letters of credit link in the header
    When I click on the manage letters of credit link in the header
    When I click the amend link on a Letter of Credit row
    Then I should be on the Request Letter of Credit Amendment page

  Scenario: The Preview Request button state
    When I visit the Request Letter of Credit Amendment page
    Then I should see the Preview Request button in its disabled state
    When I enter 1234 in the letter of credit amended amount field
    Then I should see the Preview Request button in its enabled state

  Scenario: The Preview Request button state
    When I visit the Request Letter of Credit Amendment page
    Then I should see the Preview Request button in its disabled state
    When I enter a valid business day after the expiration date in the datepicker
    Then I should see the Preview Request button in its enabled state

 
