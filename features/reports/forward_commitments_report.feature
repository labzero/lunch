@jira-mem-69
Feature: Visiting the Forward Commitments Page
  As a user
  I want to use visit the forward commitments report page for the FHLB Member Portal
  In order to view my forward commitment advances

  Background:
    Given I am logged in

  @smoke @jira-mem-546
  Scenario: Visit forward commitments report page from header link
    Given I visit the dashboard
    When I select "Forward Commitments" from the reports dropdown
    Then I should see report summary data
    And I should see a report header
    And I should see a report table with multiple data rows

  @jira-mem-546
  Scenario: Member sort the forward commitments report
    Given I am on the "Forward Commitments" report page
    Then I should see the "Funding Date" column values in "ascending" order
    When I click the "Funding Date" column heading
    Then I should see the "Funding Date" column values in "descending" order

  @data-unavailable @jira-mem-283 @jira-mem-1053
  Scenario: No data is available to show in the forward commitments report
    Given I am on the "Forward Commitments" report page
    When the "Forward Commitments" table has no data
    Then I should see an empty report table with No Records messaging

  @data-unavailable @jira-mem-282 @jira-mem-1053
  Scenario: The forward commitments has been disabled
    Given I am on the "Forward Commitments" report page
    When the "Forward Commitments" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging