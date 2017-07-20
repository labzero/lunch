Feature: Viewing/Modifying the Data Visibility of the Member Portal
  As an Admin
  I want to be able to view and control what data and reports are visible on the member portal
  So I can easily discern what the current visibility settings are and change them accordingly

  Background:
    Given I am logged into the admin panel

  @jira-mem-2452 @jira-mem-2453
  Scenario: Navigating to the Data Visibility Flags page from the admin nav
    When I click on the data visibility link in the header
    And I click on the data visibility web flags link in the header dropdown
    Then I should be on the data visibility web flags page
    And I should see 6 report tables with multiple data rows
    When I change the member selector to the 2 value on the data visibility web flags page
    Then I should see the data visibility web flags page for that member