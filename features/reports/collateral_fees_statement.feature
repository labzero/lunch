@flip-on-report-collateral-fees
@jira-mem-1387
Feature: Visiting the Collateral Monthly Fee Statement Page
  As a user
  I want to use visit the Collateral Monthly Fee Statement page for the FHLB Member Portal
  In order to view my account charges.

  Background:
    Given I am logged in

  @jira-mem-1387
  Scenario: Member sees Collateral Monthly Fee Statement
    Given I visit the dashboard
    When I select "Collateral Monthly Fee Statement" from the reports dropdown
    Then I should see report summary data
    And I should see a report header
    And I should see a report table with multiple data rows