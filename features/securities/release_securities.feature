@flip-on-securities
Feature: Releasing Securities
  As a user
  I want to release securities
  In order to pledge them with other institutions or sell them

Background:
  Given I am logged in

@jira-mem-1588
Scenario: View the released securities on the Edit Release
  When I am on the manage securities page
  When I check the 1st Pledged security
  And I remember the cusip value of the 1st Pledged security
  And I check the 2nd Pledged security
  And I remember the cusip value of the 2nd Pledged security
  And I click the button to release the securities
  Then I should see a report table with multiple data rows
  And I should see the cusip value from the 1st Pledged security in the 1st row of the securities table
  And I should see the cusip value from the 2nd Pledged security in the 2nd row of the securities table

@jira-mem-1588
Scenario: View the various Delivery Instructions field sets
  When I am on the release securities page
  Then I should see "DTC" as the selected release delivery instructions
  And I should see the "DTC" release instructions fields
  When I select "Fed" as the release delivery instructions
  Then I should see "Fed" as the selected release delivery instructions
  And I should see the "Fed" release instructions fields
  When I select "Physical" as the release delivery instructions
  Then I should see "Physical" as the selected release delivery instructions
  And I should see the "Physical" release instructions fields
  When I select "Mutual Fund" as the release delivery instructions
  Then I should see "Mutual Fund" as the selected release delivery instructions
  And I should see the "Mutual Fund" release instructions fields