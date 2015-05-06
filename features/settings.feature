Feature: Visiting the Settings Page
  As a user
  I want to use visit the settings page
  In order to change my settings

Background:
  Given I am logged in

Scenario: Navigate to settings page
  Given I visit the dashboard
  When I click on the gear icon in the header
  Then I should see "Settings" as the sidebar title

Scenario: Email Settings
  Given I visit the dashboard
    And I click on the gear icon in the header
  When I click on "Emails" in the sidebar nav
  Then I should be on the email settings page

Scenario: Changing Email Settings
  Given I am on the email settings page
    And I see the unselected state for the "reports" option
  When I check the box for the "reports" option
    Then I should see the selected state for the "reports" option
    And I should see the auto-save message for the email settings page

Scenario: Remembering Email Settings
  Given I am on the email settings page
    And I see the unselected state for the "reports" option
    And I check the box for the "reports" option
    And I should see the selected state for the "reports" option
    And I should see the auto-save message for the email settings page
  When I visit the dashboard
    And I click on the gear icon in the header
    And I click on "Emails" in the sidebar nav
  Then I should see the selected state for the "reports" option

@jira-mem-599
Scenario: Users can view Two Factor settings
  Given I visit the dashboard
    And I click on the gear icon in the header
  When I click on "2-Step Verification" in the sidebar nav
  Then I should be on the two factor settings page