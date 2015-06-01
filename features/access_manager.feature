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
    Then I should a update user success overlay
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
    Then I should a update user success overlay
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
    Then I should a update user success overlay
    When I dismiss the overlay
    Then I should see a user with the a last name of "Doe"
