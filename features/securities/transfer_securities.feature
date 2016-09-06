@flip-on-securities
Feature: Transfer Securities
  As a user
  I want to transfer securities between pledged and safekept accounts and vice versa
  In order to manage my accounts

  Background:
    Given I am logged in

  @jira-mem-1734 @jira-mem-1721
  Scenario Outline: View the transferred securities on the Edit Transfer page
    When I am on the manage securities page
    And I check the 1st <security_type> security
    And I remember the cusip value of the 1st <security_type> security
    And I check the 2nd <security_type> security
    And I remember the cusip value of the 2nd <security_type> security
    And I click the button to transfer the securities
    Then I should be on the <page> page
    And I should see a report table with multiple data rows
    And I should see the cusip value from the 1st <security_type> security in the 1st row of the securities table
    And I should see the cusip value from the 2nd <security_type> security in the 2nd row of the securities table
  Examples:
  | security_type  | page                 |
  | Pledged        | Transfer to Safekept |
  | Safekept       | Transfer to Pledged  |