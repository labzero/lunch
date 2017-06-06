Feature: Viewing/Modifying the End of Day Shutoffs for ETransact
  As an Admin
  I want to be able to view and control the end of day shutoffs for ETransact
  So I can easily discern what the current shutoffs are and change them accordingly

  Background:
    Given I am logged into the admin panel

  @jira-mem-2366
  Scenario: Navigating to the Early Shutoffs from the admin nav as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the end of day shutoff link in the header
    Then I should be on the end of day shutoff page
    And I should see the table of scheduled early shutoffs
    And I should see the end of day shutoff early shutoffs page in its view-only mode

  @jira-mem-2366
  Scenario: Navigating to the Early Shutoffs from the admin nav as an admin
    When I click on the trade credit rules link in the header
    And I click on the end of day shutoff link in the header
    Then I should be on the end of day shutoff page
    And I should see the table of scheduled early shutoffs
    And I should see the end of day shutoff early shutoffs page in its editable mode