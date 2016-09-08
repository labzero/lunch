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

  @jira-mem-1715
  Scenario Outline: Member views edit securities instructions
    Given I am on the transfer to <page> account securities page
    When I click on the Edit Securities link
    Then I should see instructions on how to edit securities
    When I click on the Edit Securities link
    Then I should not see instructions on how to edit securities
  Examples:
    | page     |
    | pledged  |
    | safekept |
    
  Scenario: Authorized signer views legal copy for pledge transfers
    Given I am logged in as a "quick-advance signer"
    And I am on the manage securities page
    And I check the 1st Safekept security
    When I click the button to transfer the securities
    Then I should see the pledge legal copy

  Scenario: Authorized signer does not view legal copy for safekept transfers
    Given I am logged in as a "quick-advance signer"
    And I am on the manage securities page
    And I check the 1st Pledged security
    When I click the button to transfer the securities
    Then I should not see the pledge legal copy

  @jira-mem-1716 @data-unavailable
  Scenario Outline: Member uploads an edited securities file that is valid
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I upload a securities transfer file
    And I wait for the securities file to upload
    Then I should see an uploaded transfer security with a description of "Zip Zoop Zap"
    And I should see an uploaded transfer security with an original par of "123,456,789"
  Examples:
    | page     |
    | pledged  |
    | safekept |
