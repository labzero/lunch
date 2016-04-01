Feature: Visiting the Access Manager page
  As an Access Manager
  I want to manage my bank's users
  In order to handle support requests

Background:
  Given I am logged in as an "access manager"

  @jira-mem-561
  Scenario: Users who are Access Managers can view the access manager page
    When I visit the access manager page
    Then I should see a list of users

  @jira-mem-562
  Scenario: Users who are Access Managers can lock and unlock user accounts
    Given I visit the access manager page
    When I lock a user
    Then I should see a locked user success overlay
    When I dismiss the overlay
    And I unlock a user
    Then I should see an unlocked user success overlay

  @jira-mem-566
  Scenario: Access Managers can edit a user
    Given I visit the access manager page
    When I edit a user
    Then I should see an edit user form overlay
    When I cancel the overlay
    Then I should not see an edit user form overlay

  @jira-mem-566
  Scenario: Access Managers can edit a user's email
    Given I visit the access manager page
    When I edit a user
    And I enter "test@example.com" for the email
    And I enter "bar@example.com" for the email confirmation
    And I submit the edit user form
    Then I should see a confirmation mismatch email error
    When I enter "test@example.com" for the email confirmation
    And I submit the edit user form
    Then I should see an update user success overlay
    When I dismiss the overlay
    Then I should see a user with the an email of "test@example.com"

  @jira-mem-566
  Scenario: Access Managers can edit a user's first name
    Given I visit the access manager page
    When I edit a user
    And I enter "" for the first name
    And I submit the edit user form
    Then I should see a blank first name error
    When I enter "John" for the first name
    And I submit the edit user form
    Then I should see an update user success overlay
    When I dismiss the overlay
    Then I should see a user with the a first name of "John"

  @jira-mem-566
  Scenario: Access Managers can edit a user's last name
    Given I visit the access manager page
    When I edit a user
    And I enter "" for the last name
    And I submit the edit user form
    Then I should see a blank last name error
    When I enter "Doe" for the last name
    And I submit the edit user form
    Then I should see an update user success overlay
    When I dismiss the overlay
    Then I should see a user with the a last name of "Doe"

  @jira-mem-563
  Scenario: Access Manangers can reset a user's password
    Given I visit the access manager page
    When I reset the password for a user
    Then I should see a reset password overlay

  @jira-mem-565
  Scenario: Access Managers can't create a user with validation errors
    Given I visit the access manager page
    When I create a new user
    And I enter "" for the first name
    And I submit the new user form
    Then I should see a blank first name error
    When I enter "John" for the first name
    And I enter "" for the last name
    And I submit the new user form
    Then I should see a blank last name error
    When I enter "Doe" for the last name
    And I enter "fhlbsf1234" for the username
    And I submit the new user form
    Then I should see a invalid username error
    And I enter "1234" for the username
    And I submit the new user form
    Then I should see a invalid username error
    And I enter "ab" for the username
    And I submit the new user form
    Then I should see a too short[4] username error
    And I enter "abcdefghijabcdefghijabcdefghij" for the username
    And I submit the new user form
    Then I should see a too long[20] username error
    And I enter "u123" for the username
    And I enter "" for the email
    And I submit the new user form
    Then I should see a blank email error
    And I enter "jdoe@gmail.com" for the email
    And I submit the new user form
    Then I should see a confirmation mismatch email error
    And I enter "jdoe@gmail.com" for the email confirmation
    Then I should not see any validations errors

  @jira-mem-565 @local-only
  Scenario: Access Managers can create a new user
    Given I visit the access manager page
    When I create a new user
    And I enter "New" for the first name
    And I enter "User" for the last name
    And I enter "newuser" for the username
    And I enter "newuser@gmail.com" for the email
    And I enter "newuser@gmail.com" for the email confirmation
    And I submit the new user form
    Then I should see a new user success overlay
    When I dismiss the overlay
    Then I should see a user with the a last name of "User"

  @jira-mem-564
  Scenario: Access Managers must select a reason why they are deleting a user
    Given I visit the access manager page
    When I edit a non-access manager
    And I click the delete user button
    Then I should see the confirm delete overlay
    And the confirm delete user button should be disabled
    When I select a reason
    Then the confirm delete user button should be enabled

  @jira-mem-564
  Scenario: Access Managers can't delete themselves
    Given I visit the access manager page
    When I edit an access manager
    Then I should see the delete user button disabled

  @jira-mem-564
  Scenario: Access Managers can delete a user
    Given I visit the access manager page
    And I edit the deletable user
    And I click the delete user button
    When I select a reason
    And I submit the delete user form
    Then I should see the user deleted overlay

  @jira-mem-1474
  Scenario: Read-only access managers can see non-editable list of users
    Given I am logged in as a "read-only access manager"
    When I visit the access manager page
    Then I should see a list of users
    Then I should see the lock user button disabled
    Then I should see the reset-password user button disabled
    Then I should see the edit user button disabled