@jira-mem-69
Feature: Visiting the Current Securities Position Report Page
  As a user
  I want to use visit the current securities position report page for the FHLB Member Portal
  In order to view my current securities position

  Background:
    Given I am logged in

  @smoke @jira-mem-580
  Scenario: Visit current securities position report page from header link
    Given I visit the dashboard
    When I select "Current Securities Position" from the reports dropdown
    Then I should see report summary data
    And I should see a report header
    And I should see a report table with multiple data rows

  @jira-mem-580
  Scenario: Viewing the details of a given security
    Given I am on the "Current Securities Position" report page
    When I click on the view cell for the first security
    Then I should see the detailed view for the first security
    When I click on the hide link for the first security
    Then I should not see the detailed view for the first security

  @smoke @jira-mem-580
  Scenario: Member sorts the current securities position report by maturity date
    Given I am on the "Current Securities Position" report page
    When I click the "Maturity Date" column heading
    Then I should see the "Maturity Date" column values in "ascending" order
    And I click the "Maturity Date" column heading
    Then I should see the "Maturity Date" column values in "descending" order

  @jira-mem-580
  Scenario: Member filters the current securities position report
    Given I am on the "Current Securities Position" report page
    When I filter the report by "Pledged Securities"
    Then I should see a current securities position report for Pledged Securities
    When I filter the report by "Unpledged Securities"
    Then I should see a current securities position report for Unpledged Securities

  @data-unavailable @jira-mem-283
  Scenario: No data is available to show in the current securities position report
    Given I am on the "Current Securities Position" report page
    When the "Current Securities Position" table has no data
    Then I should see an empty report table with Data Unavailable messaging

  @data-unavailable @jira-mem-282
  Scenario: The current securities position report has been disabled
    Given I am on the "Current Securities Position" report page
    When the "Current Securities Position" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging