@jira-mem-69 @wip
Feature: Visiting the Capital Stock Position and Leverage Report
  As a user
  I want to use visit the Capital Stock Position and Leverage Report page for the FHLB Member Portal
  In order to view my current capital stock position and leverage

  Background:
    Given I am logged in

  @smoke @jira-mem-617 @wip
  Scenario: Visit current capital stock position and leverage report page from header link
    Given I visit the dashboard
    When I select "Capital Stock Position and Leverage Statement" from the reports dropdown
    Then I should see 2 report tables with multiple data rows
    And I should see a report header

  @data-unavailable @jira-mem-283 @jira-mem-1053 @wip
  Scenario: No data is available to show in the putable advances parallel shift sensitivity analysis report
    Given I am on the "Capital Stock Position and Leverage Statement" report page
    When the "Capital Stock Position and Leverage Statement" table has no data
    Then I should see an empty report table with No Records messaging

  @data-unavailable @jira-mem-282 @jira-mem-1053 @wip
  Scenario: The putable advances parallel shift sensitivity analysis report has been disabled
    Given I am on the "Capital Stock Position and Leverage Statement" report page
    When the "Capital Stock Position and Leverage Statement" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging
