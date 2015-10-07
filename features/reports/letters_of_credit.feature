@jira-mem-69
Feature: Visiting the Letters of Credit Report Page
  As a user
  I want to use visit the letters of credit report page for the FHLB Member Portal
  In order to view

  Background:
    Given I am logged in

  @smoke @jira-mem-545
  Scenario: Visit letters of credit report page from header link
    Given I visit the dashboard
    When I select "Letters of Credit" from the reports dropdown
    Then I should see report summary data
    And I should see a report header
    And I should see a report table with multiple data rows

  @data-unavailable @jira-mem-283 @jira-mem-1053
  Scenario: No data is available to show in the letters of credit report
    Given I am on the "Letters of Credit" report page
    When the "Letters of Credit" table has no data
    Then I should see an empty report table with No Records messaging

  @data-unavailable @jira-mem-282 @jira-mem-1053
  Scenario: The letters of credit report has been disabled
    Given I am on the "Letters of Credit" report page
    When the "Letters of Credit" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging