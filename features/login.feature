@jira-mem-71
Feature: Logging in to the Member Site
  As a user
  I want to be able to securely authenticate with the Member Portal
  In order to access my bank's information.

@smoke @jira-mem-494
Scenario: User logs in
  Given I visit the root path
  When I log in
  Then I should see dashboard modules

@smoke @jira-mem-494
Scenario: Extranet User logs in
  Given I visit the root path
  When I log in as an "extranet user"
  Then I should see dashboard modules

Scenario: User logs out
  Given I am logged in
  When I log out
  Then I should be logged out

Scenario: User has wrong password
  Given I visit the root path
  When I log in with a bad password
  Then I should see a bad login error

Scenario: User has wrong username
  Given I visit the root path
  When I log in with a bad username
  Then I should see a bad login error

@jira-mem-502
Scenario: User selects a member bank on login
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form
  Then I should see the member bank selector
  And I should see the member bank selector submit button disabled
  When I select the 1st member bank
  Then I should see dashboard modules

@smoke @jira-mem-305
Scenario: User associated with a bank does not select a member bank on login
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form as a user belonging to a member bank
  Then I should see dashboard modules

@jira-mem-502
Scenario: User logs out without selecting a member bank
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form
  Then I should see the member bank selector
  When I log out
  Then I should be logged out