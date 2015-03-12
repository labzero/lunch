Feature: Visiting the Dashboard
  As a user
  I want to use visit the dashboard for the FHLB Member Portal
  In order to find information

Background:
  Given I am logged in

  @smoke
  Scenario: Visit dashboard
    When I visit the dashboard
    Then I should see dashboard modules

  Scenario: See dashboard contacts
    When I visit the dashboard
    Then I should see 2 contacts

  @smoke
  Scenario: See dashboard quick advance module
    When I visit the dashboard
    Then I should see a dollar amount field
      And I should see an advance rate.

  @smoke
  Scenario: See Your Account module
    When I visit the dashboard
    Then I should see the Your Account table breakdown
      And I should see the Anticipated Activity graph
      And I should see a pledged collateral gauge
      And I should see a total securities gauge
      And I should see an effective borrwoing capacity gauge

  @smoke
  Scenario: See dashboard market overview graph
    When I visit the dashboard
    Then I should see a market overview graph

  Scenario: Quick Advance flyout opens
    When I visit the dashboard
      And I enter "56503000" into the ".dashboard-module-advances input" input field
    Then I should see a flyout
      And I should see "56503000" in the quick advance flyout input field

  @smoke
  Scenario: Quick Advance flyout closes
    When I visit the dashboard
      And I open the quick advance flyout
      And I click on the flyout close button
    Then I should not see a flyout

  @jira-mem-229 @jira-mem-506
  Scenario: Quick Advance flyout table
    When I visit the dashboard
      And I open the quick advance flyout
    Then I should see the quick advance table
      And I should see a rate for the "overnight" term with a type of "whole"
      And I should see the selected state for the cell with a term of "overnight" and a type of "whole" 

  Scenario: Quick Advance flyout tooltip
    Given I visit the dashboard
      And I open the quick advance flyout
    When I hover on the cell with a term of "overnight" and a type of "whole"
    Then I should see the quick advance table tooltip for the cell with a term of "overnight" and a type of "whole"

  Scenario: Select rate from Quick Advance flyout table
    Given I visit the dashboard
      And I open the quick advance flyout
      And I see the unselected state for the cell with a term of "open" and a type of "whole"
    When I select the rate with a term of "open" and a type of "whole"
    Then I should see the selected state for the cell with a term of "open" and a type of "whole"
      And the initiate advance button should be active

  Scenario: Preview rate from Quick Advance flyout table
    Given I visit the dashboard
      And I open the quick advance flyout
      And I select the rate with a term of "overnight" and a type of "whole"
    When I click on the initiate advance button
    Then I should not see the quick advance table
      And I should see a preview of the quick advance

  @smoke
  Scenario: Go back to rate table from preview in Quick Advance flyout
    Given I visit the dashboard
      And I open the quick advance flyout
      And I select the rate with a term of "1week" and a type of "aaa"
      And I click on the initiate advance button
    Then I should not see the quick advance table
    When I click on the back button for the quick advance preview
    Then I should see the quick advance table
      And I should see the selected state for the cell with a term of "1week" and a type of "aaa"
      And I should not see a preview of the quick advance

  Scenario: Confirm rate from Quick Advance preview dialog
    Given I visit the dashboard
      And I open the quick advance flyout
      And I select the rate with a term of "overnight" and a type of "whole"
      And I click on the initiate advance button
      And I should not see the quick advance table
      And I should see a preview of the quick advance
    When I click on the quick advance confirm button
    Then I should see confirmation number for the advance
      And I should not see the quick advance preview message
      And I should see the quick advance confirmation close button

  Scenario: Close flyout after finishing quick advance
    Given I visit the dashboard
      And I successfully execute a quick advance
      And I should see a flyout
    When I click on the quick advance confirmation close button
      Then I should not see a flyout

  Scenario: Default selection in Quick Advance flyout
    Given I visit the dashboard
    When I open the quick advance flyout
    Then I should see the selected state for the cell with a term of "overnight" and a type of "whole"

  @data-unavailable @jira-mem-408
  Scenario: Data for Aggregate 30 Day Terms module is temporarily unavailable
    When I visit the dashboard
    Then the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state
