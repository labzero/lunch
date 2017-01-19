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