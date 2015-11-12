Feature: Fee Schedules Page
  As a user
  I want to see Fee Schedules Page
  In order to view the fees and charges for FHLB services

  Background:
    Given I am logged in

  @smoke @jira-mem-702
  Scenario: Member navigates to the fee schedules page via the resources dropdown
    Given I hover on the resources link in the header
    When I click on the fee schedules link in the header
    Then I should see the fee schedules page
    And I should see 12 report tables with multiple data rows