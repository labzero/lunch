Feature: Guides Page
  As a user
  I want to see Bank provided guides
  In order to understand how the Bank system works

Background:
  Given I am logged in

Scenario: Member navigates to the guides page via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the guides link in the header
  Then I should see the guides page

Scenario: Member sees guides on the guide summary page
  Given I am on the guides page
  Then I should see at least one guide

Scenario: Member sees guide update summaries on the guide summary page
  Given I am on the guides page
  Then I should see at least one guide update summary