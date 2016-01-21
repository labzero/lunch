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

@wip @smoke
Scenario: Email Settings
  Given I visit the dashboard
    And I click on the gear icon in the header
  When I click on "Emails" in the sidebar nav
  Then I should be on the email settings page

@wip
Scenario: Changing Email Settings
  Given I am on the email settings page
    And I see the unselected state for the "reports" option
  When I check the box for the "reports" option
    Then I should see the selected state for the "reports" option
    And I should see the auto-save message for the email settings page

@wip
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
  When I click on "Manage Token" in the sidebar nav
  Then I should be on the two factor settings page
  And I should not see any success or failure messages

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

  @jira-mem-1030
  Scenario: Users can set their SecurID PIN
    Given I am on the two factor authentication settings page
    When I click on the new token PIN CTA
    Then I should see the new PIN form
    When I cancel setting the PIN
    Then I should not see the new PIN form

  @jira-mem-1030
  Scenario: Users are informed if they have entered bad details on the new PIN form
    Given I am on the new PIN page
    And I enter a bad token
    And I submit the new PIN form
    Then I should see the invalid token message
    When I enter a good token
    And I enter a bad new PIN
    And I submit the new PIN form
    Then I should see the invalid PIN message
    When I enter a good new PIN
    And I enter a bad confirm PIN
    And I submit the new PIN form
    Then I should see the invalid PIN message
    When I enter two different values for the new PIN
    And I submit the new PIN form
    Then I should see the failed to set PIN message

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

  @smoke @jira-mem-561
  Scenario: Users who are not Access Managers can't view the access manager page
    Given I visit the dashboard
    When I click on the gear icon in the header
    Then I should not see "Access Manager" in the sidebar nav

  @jira-mem-920 @jiram-mem-1021
  Scenario: User changes their password
    Given I am logged in as a "password change user"
    When I am on the change password page
    Then I should see current password validations
    When I fill in the current password field with the password change user's password
    Then I should see password change validations
    When I enter a valid new password
    And I submit the form
    Then I should see the change password page
    And I should see a success flash
    When I log out
    And I login as the password change user with the new password
    Then I should be logged in

  @jira-mem-1084
  Scenario: User uses the wrong password to change their password
    Given I am logged in
    And I am on the change password page
    When I enter a bad current password
    And I enter a valid new password
    And I submit the form
    Then I should not see an error flash

  @jira-mem-1068
  Scenario: User password confirmation does not match in change password flow
    Given I am logged in
    And I am on the change password page
    And I fill in the current password field with the password change user's password
    And I enter a new valid password in the first field
    When I focus on the password confirmation field
    Then I should not see a password match error
    When I focus on the new password field
    Then I should not see a password match error
    When I try to submit the form
    Then I should see a password match error
    When I enter a new valid password in the password confirmation field
    And I focus on the new password field
    Then I should not see a password match error
