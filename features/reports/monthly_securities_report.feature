@jira-mem-69 @flip-on-report-monthly-securities-positions
Feature: Visiting the Monthly Securities Position Report Page
  As a user
  I want to use visit the monthly securities position report page for the FHLB Member Portal
  In order to view my monthly securities position

  Background:
    Given I am logged in

  @smoke @jira-mem-541
  Scenario: Visit monthly securities position report page from header link
    Given I visit the dashboard
    When I select "Monthly Securities Position" from the reports dropdown
    Then I should see report summary data
    And I should see a report header
    And I should see a report table with multiple data rows

  @jira-mem-541
  Scenario: Viewing the details of a given security
    Given I am on the "Monthly Securities Position" report page
    When I click on the view cell for the first security
    Then I should see the detailed view for the first security
    When I click on the hide link for the first security
    Then I should not see the detailed view for the first security

  @smoke @jira-mem-541
  Scenario: Member sorts the monthly securities position report by maturity date
    Given I am on the "Monthly Securities Position" report page
    When I click the "Maturity Date" column heading
    Then I should see the "Maturity Date" column values in "ascending" order
    And I click the "Maturity Date" column heading
    Then I should see the "Maturity Date" column values in "descending" order

  @jira-mem-541
  Scenario: Member filters the monthly securities position report
    Given I am on the "Monthly Securities Position" report page
    When I filter the report by "Pledged Securities"
    Then I should see a monthly securities position report for Pledged Securities
    When I filter the report by "Unpledged Securities"
    Then I should see a monthly securities position report for Unpledged Securities

  @jira-mem-890
  Scenario: Member enters a date occurring before the minimum allowed date
    Given I am on the "Monthly Securities Position" report page
    When I click the datepicker field
    And I write "1/10/2013" in the datepicker start input field
    And I click the datepicker apply button
    Then I should see a "Monthly Securities Position" report as of 18 months ago

  @jira-mem-890
  Scenario: Member enters a date occurring after the maximum allowed date
    Given I am on the "Monthly Securities Position" report page
    When I click the datepicker field
    And I write tomorrow's date in the datepicker start input field
    And I click the datepicker apply button
    Then I should see a "Monthly Securities Position" report as of the end of the last valid month

  @jira-mem-890 @jira-mem-1220
  Scenario: Member enters a date occurring after the maximum allowed date on the last day of the month
    Given that today's date is the last day of last month
    And I am on the "Monthly Securities Position" report page
    When I click the datepicker field
    And I write tomorrow's date in the datepicker start input field
    And I click the datepicker apply button
    Then I should see a "Monthly Securities Position" report as of the last day of last month

  @jira-mem-890 @jira-mem-1220
  Scenario: Member enters a date occurring after the maximum allowed date on the first day of the month
    Given that today's date is the first day of this month
    And I am on the "Monthly Securities Position" report page
    When I click the datepicker field
    And I write tomorrow's date in the datepicker start input field
    And I click the datepicker apply button
    Then I should see a "Monthly Securities Position" report as of the last day of last month

  @resque-backed @smoke @jira-mem-821
  Scenario: Member downloads an XLSX of the monthly securities position report
    Given I am on the "Monthly Securities Position" report page
    When I request an XLSX
    Then I should begin downloading a file

  @data-unavailable @jira-mem-283 @jira-mem-1053
  Scenario: No data is available to show in the monthly securities position report
    Given I am on the "Monthly Securities Position" report page
    When the "Monthly Securities Position" table has no data
    Then I should see an empty report table with No Records messaging

  @data-unavailable @jira-mem-282 @jira-mem-1053
  Scenario: The monthly securities position report has been disabled
    Given I am on the "Monthly Securities Position" report page
    When the "Monthly Securities Position" report has been disabled
    Then I should see an empty report table with Data Unavailable messaging