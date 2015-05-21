Feature: Visiting the Settings Page
  As a user
  I want to use visit the settings page
  In order to change my settings

Background:
  Given I am logged in

@smoke
Scenario: Navigate to settings page
  Given I visit the dashboard
  When I click on the gear icon in the header
  Then I should see "Settings" as the sidebar title

@smoke
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

@smoke @jira-mem-599
Scenario: Users can view Two Factor settings
  Given I visit the dashboard
    And I click on the gear icon in the header
  When I click on "2-Step Verification" in the sidebar nav
  Then I should be on the two factor settings page

@jira-mem-600
Scenario: Users can reset their SecurID PIN
  Given I am on the two factor authentication settings page
  When I click on the reset token PIN CTA
  Then I should see the reset PIN form
  When I cancel resetting the PIN
  Then I should not see the reset PIN form

@jira-mem-600
Scenario: Users are informed if they have entered bad details on the reset PIN form
  Given I am on the reset PIN page
  When I enter a bad current PIN
  And I submit the reset PIN form
  Then I should see the invalid PIN message
  When I enter a good current PIN
  And I enter a bad token
  And I submit the reset PIN form
  Then I should see the invalid token message
  When I enter a good token
  And I enter a bad new PIN
  And I submit the reset PIN form
  Then I should see the invalid PIN message
  When I enter a good new PIN
  And I enter a bad confirm PIN
  And I submit the reset PIN form
  Then I should see the invalid PIN message
  When I enter two different values for the new PIN
  And I submit the reset PIN form
  Then I should see the failed to reset PIN message

  @jira-mem-601
  Scenario: Users can resynchronize their SecurID token
    Given I am on the two factor authentication settings page
    When I click on the resynchronize token CTA
    Then I should see the resynchronize token form
    When I cancel resynchronizing the token
    Then I should not see the resynchronize token form

  @jira-mem-601
  Scenario: Users are informed if they have entered bad details on the resynchronize token form
    Given I am on the resynchronize token page
    When I enter a bad current PIN
    And I submit the resynchronize token form
    Then I should see the invalid PIN message
    When I enter a good current PIN
    And I enter a bad token
    And I submit the resynchronize token form
    Then I should see the invalid token message
    When I enter a good token
    And I enter a bad next token
    And I submit the resynchronize token form
    Then I should see the invalid token message
    When I enter a good next token
    And I submit the resynchronize token form
    Then I should see the failed to resynchronize token message

  @jira-mem-561
  Scenario: Users who are Access Managers can view the access manager page
    Given I am logged in as an "access manager"
    When I visit the access manager page
    Then I should see a list of users

  @jira-mem-562
  Scenario: Users who are Access Managers can lock and unlock user accounts
    Given I am logged in as an "access manager"
    When I visit the access manager page
    And I lock a user
    Then I should see a locked user success overlay
    When I dismiss the overlay
    And I unlock a user
    Then I should see an unlocked user success overlay

  @smoke @jira-mem-561
  Scenario: Users who are not Access Managers can't view the access manager page
    Given I visit the dashboard
    And I click on the gear icon in the header
    Then I should not see "Access Manager" in the sidebar nav
