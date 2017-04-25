Feature: Viewing/Modifying the Term/Credit Rules
  As an Admin
  I want to be able to view and control the term and credit rules
  So I can easily discern what the current limits are and change them accordingly

  Background:
    Given I am logged into the admin panel

  @local-only @jira-mem-2303
  Scenario: Navigating to the Term Limits page from the admin nav as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the term rules link in the header
    Then I should be on the term rules limits page
    And the term rules daily limits tab should be active
    And I should see 2 report tables with multiple data rows
    And I should see the term rules limits page in view-only mode

  @jira-mem-2305
  Scenario: Navigating to the Term Limits page from the admin nav as an admin
    When I click on the trade credit rules link in the header
    And I click on the term rules link in the header
    Then I should be on the term rules limits page
    And the term rules daily limits tab should be active
    And I should see 2 report tables with multiple data rows
    And I should see the term rules limits page in its editable mode

  @local-only @jira-mem-2305
  Scenario: Updating the Term Limits
    Given I am on the term rules limits page
    And I should see the term rules limits page in its editable mode
    When I click the save changes button for the rules limits form
    Then I should be on the term rules limits page
    And I should see the success message on the term rules limits page

  @jira-mem-2308
  Scenario: Navigating to the Rate Bands page
    When I click on the trade credit rules link in the header
    And I click on the term rules link in the header
    And I click on the term rules rate bands tab
    Then the term rules rate bands tab should be active
    And I should see 1 report tables with multiple data rows