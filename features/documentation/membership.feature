Feature: Membership Overview Page
  As a user
  I want to see the membership overview page
  In order to learn more about becoming a member

  Background:
    Given I am logged in

  @smoke @jira-mem-1254
  Scenario: Member navigates to the membership overview page via the resources dropdown
    Given I hover on the resources link in the header
    When I click on the membership link in the header
    Then I should be on the membership resource page