@jira-mem-69
Feature: Visiting the Cash Projections Report Page
  As a user
  I want to use visit the cash projections report page for the FHLB Member Portal
  In order to view my cash projections as of the last business day

  Background:
    Given I am logged in

  @smoke @jira-mem-367
  Scenario: Visit cash projections report page from header link
    Given I visit the dashboard
    When I select "Cash Projections Detail Report" from the reports dropdown
    Then I should see report summary data
    And I should see a report table with multiple data rows

  @jira-mem-367
  Scenario: Viewing the details of a given projection
    Given I am on the "Cash Projections" page
    When I click on the view cell for the first cash projection
    Then I should see the detailed view for the first cash projection
    When I click on the hide link for the first cash projection
    Then I should not see the detailed view for the first cash projection

  @smoke @jira-mem-367
  Scenario: Member sorts the cash projections report by settlement date
    Given I am on the "Cash Projections" page
    When I click the "Settlement Date" column heading
    Then I should see the "Settlement Date" column values in "ascending" order
    And I click the "Settlement Date" column heading
    Then I should see the "Settlement Date" column values in "descending" order

  @data-unavailable @jira-mem-283
  Scenario: No data is available to show in the cash projections report
    Given I am on the "Cash Projections" page
    When the "Cash Projections" table has no data
    Then I should see an empty report table with Data Unavailable messaging

  @data-unavailable @jira-mem-282
  Scenario: The cash projections report has been disabled
    Given I am on the "Cash Projections" page
    When the "Cash Projections" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging