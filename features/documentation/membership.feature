@flip-on-unfinished-membership
Feature: Membership Pages
  As a user
  I want to see the membership pages
  In order to learn more about becoming a member and access membership resources

  Background:
    Given I am logged in

  @smoke @jira-mem-1254
  Scenario: Member navigates to the membership overview page via the resources dropdown
    Given I hover on the resources link in the header
    When I click on the membership link in the header
    Then I should be on the membership "overview" page

  @smoke @jira-mem-695
  Scenario: Member navigates to the membership applications page via the resources dropdown
    Given I hover on the resources link in the header
    When I click on the applications link in the header
    Then I should be on the membership "applications" page