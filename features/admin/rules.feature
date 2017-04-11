Feature: Viewing/Modifying the Term/Credit Rules
  As an Admin
  I want to be able to view and control the term and credit rules
  So I can easily discern what the current limits are and change them accordingly

  Background:
    Given I am logged into the admin panel

  Scenario: Navigating to the Term Limits page from the admin nav
    When I click on the trade credit rules link in the header
    And I click on the term rules link in the header
    Then I should be on the term rules limits page
    And the term rules daily limits tab should be active
    And I should see 2 report tables with multiple data rows