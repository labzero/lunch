@jira-mem-69
Feature: Visiting Today's Credit Report
  As a user
  I want to visit Today's Credit Report on the FHLB Member Portal
  In order to view my bank's credit activity as of today

  Background:
    Given I am logged in

  @smoke @jira-mem-868
  Scenario: Visit Today's Credit report page from header link
    Given I visit the dashboard
    When I select "Today's Credit" from the reports dropdown
    And I should see a report table with multiple data rows

  @data-unavailable @jira-mem-283 @jira-mem-1053
  Scenario: No data is available to show in the Today's Credit report
    Given I am on the "Today's Credit" report page
    When the "Today's Credit" table has no data
    Then I should see an empty report table with No Records messaging

  @data-unavailable @jira-mem-282 @jira-mem-1053
  Scenario: The Today's Credit report has been disabled
    Given I am on the "Today's Credit" report page
    When the "Today's Credit" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging