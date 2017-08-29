Feature: Viewing/Modifying the Data Visibility of the Member Portal
  As an Admin
  I want to be able to view and control what data and reports are visible on the member portal
  So I can easily discern what the current visibility settings are and change them accordingly

  Background:
    Given I am logged into the admin panel

  @jira-mem-2452 @jira-mem-2453
  Scenario: Navigating to the Data Visibility Flags page from the admin nav as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the data visibility link in the header
    And I click on the data visibility web flags link in the header dropdown
    Then I should be on the data visibility web flags page
    And I should see the data visibility web flags page in its view-only mode
    And I should see 6 report tables with multiple data rows
    When I change the member selector to the 2 value on the data visibility web flags page
    Then I should see the data visibility web flags page for that member

  @jira-mem-2594
  Scenario: Navigating to the Data Visibility Flags page from the admin nav as an etransact admin
    Given I am logged into the admin panel as an etransact admin
    When I click on the data visibility link in the header
    And I click on the data visibility web flags link in the header dropdown
    Then I should be on the data visibility web flags page
    And I should see the data visibility web flags page in its view-only mode
    And I should see 6 report tables with multiple data rows
    When I change the member selector to the 2 value on the data visibility web flags page
    Then I should see the data visibility web flags page for that member

  @jira-mem-2452 @jira-mem-2453
  Scenario: Navigating to the Data Visibility Flags page from the admin nav
    When I click on the data visibility link in the header
    And I click on the data visibility web flags link in the header dropdown
    Then I should be on the data visibility web flags page
    And I should see the data visibility web flags page in its editable mode
    And I should see 6 report tables with multiple data rows
    When I change the member selector to the 2 value on the data visibility web flags page
    Then I should see the data visibility web flags page for that member

  @jira-mem-2455 @jira-mem-2456 @jira-mem-2458 @local-only
  Scenario: Toggling data visibility as an admin
    Given I am on the data visibility web flags page
    When I click to toggle the state of the first data source
    Then I should see the first data source in its disabled state
    When I click to save the data visibility changes
    Then I should see the success message on the data visibility flags page
    When I click to toggle the state of the first data source
    And I click to save the data visibility changes but there is an error
    Then I should see the error message on the data visibility flags page
    When I change the member selector to the 2 value on the data visibility web flags page
    Then I should see the data visibility web flags page for that member
    When I click to toggle the state of the first data source
    Then I should see the first data source in its disabled state
    When I click to save the data visibility changes
    Then I should see the success message on the data visibility flags page for that member
    When I click to toggle the state of the first data source
    And I click to save the data visibility changes but there is an error
    Then I should see the error message on the data visibility flags page for that member