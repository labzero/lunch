@flip-on-letters-of-credit
@flip-on-letters-of-credit-amend
Feature: Authorize a Letter of Credit Amendment Request
  As a user
  I want to authorize a Letter of Credit Amendment Request

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-1971
  Scenario: Successfully executing the Letter of Amendment Request
    Given I visit the Preview Letter of Credit Amendment page
    When I enter my SecurID pin
    And I enter my SecurID token
    And I click the Authorize Request button
    Then I should be on the Letter of Credit Amendment Success page

  @jira-mem-1971
  Scenario: Navigating to the Manage Letter of Credit page from the success page
    Given I visit the Letter of Credit Amendment Success page
    When I click the Manage Letters of Credit button
    Then I should be on the Manage Letters of Credit page

  @jira-mem-2181
  Scenario: User downloads the Letter of Credit Request
    Given I visit the Letter of Credit Amendment Success page
    When I click the Download Letter of Credit Request button
    Then I should begin downloading a file