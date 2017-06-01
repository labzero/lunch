@flip-on-securities
Feature: Managing Securities
  As a user
  I want to visit the Manage Securities page
  In order to manage my securities

Background:
  Given I am logged in

@smoke @jira-mem-1295
Scenario: Visit Manage Securities from the header
  Given I visit the dashboard
  When I click on the securities link in the header
  When I click on the manage securities link in the header
  Then I should be on the Manage Securities page
  Then I should see a report table with multiple data rows

@jira-mem-1587
Scenario: Member filters securities
  Given I am on the manage securities page
  When I filter the securities by Safekept
  Then I should only see Safekept rows in the securities table
  When I filter the securities by Pledged
  Then I should only see Pledged rows in the securities table

@jira-mem-1587 @jira-mem-1736
Scenario Outline: Active state of Submit Button
  When I am on the manage securities page
  Then the <action> securities button should be inactive
  When I check the 1st Pledged security
  Then the <action> securities button should be active
  When I check the 2nd Pledged security
  Then the <action> securities button should be active
  When I check the 1st Safekept security
  Then the <action> securities button should be inactive
  When I uncheck the 1st Safekept security
  Then the <action> securities button should be active
  When I check the 1st Safekept security
  Then the <action> securities button should be inactive
  When I uncheck the 1st Pledged security
  Then the <action> securities button should be inactive
  When I uncheck the 2nd Pledged security
  Then the <action> securities button should be active
  When I filter the securities by Safekept
  Then the <action> securities button should be inactive
  When I check the box to select all displayed securities
  Then the <action> securities button should be active
  When I filter the securities by Pledged
  Then the <action> securities button should be inactive
  When I check the box to select all displayed securities
  Then the <action> securities button should be active
  When I filter the securities by All
  Then the <action> securities button should be inactive
  Examples:
  | action   |
  | release  |
  | transfer |

  @jira-mem-2360
Scenario: Member sorts the Securities list
  Given I am on the manage securities page
  When I click the "CUSIP" column heading on the "Manage Securities" table
  Then I should see the "CUSIP" column values in "ascending" order
  When I click the "Description" column heading on the "Manage Securities" table
  Then I should see the "Description" column values in "ascending" order
  When I click the "Status" column heading on the "Manage Securities" table
  Then I should see the "Status" column values in "ascending" order
  When I click the "Eligibility" column heading on the "Manage Securities" table
  Then I should see the "Eligibility" column values in "ascending" order
  When I click the "Maturity Date" column heading on the "Manage Securities" table
  Then I should see the "Maturity Date" column values in "ascending" order
  When I click the "Authorized By" column heading on the "Manage Securities" table
  Then I should see the "Authorized By" column values in "ascending" order
  When I click the "Current Par ($)" column heading on the "Manage Securities" table
  Then I should see the "Current Par ($)" column values in "ascending" order
  When I click the "Borrowing Capacity ($)" column heading on the "Manage Securities" table
  Then I should see the "Borrowing Capacity ($)" column values in "ascending" order