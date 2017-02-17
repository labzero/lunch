@flip-on-letters-of-credit
Feature: Executing a New Letter of Credit Request
  As a user
  I want to execute a request for a New Letter of Credit
  In order to begin the process by which the Letter of Credit will be issued

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-1971
  Scenario: Successfully executing the New Letter of Request
    Given I visit the Preview Letter of Credit page
    When I enter my SecurID pin
    And I enter my SecurID token
    And I click the Authorize Request button
    Then I should be on the Letter of Credit Request Success page

  @jira-mem-1971
  Scenario: Navigating to the Manage Letter of Credit page from the success page
    Given I visit the Letter of Credit Success page
    When I click the Manage Letters of Credit button
    Then I should be on the Manage Letters of Credit page

  @jira-mem-1971
    Scenario: Make a new request from the success page
    Given I visit the Letter of Credit Success page
    When I click the Make a New Request button
    Then I should be on the New Letter of Credit Request page

  @jira-mem-2146
  Scenario: Internal user attempts to execute a New Letter of Credit Request
    Given I am logged in as an "intranet user"
    When I visit the Preview Letter of Credit page
    And I click the Authorize Request button
    Then I should be on the Preview Letter of Credit Request page
    And I should see the "internal user not authorized" form error