Feature: Logging in to the Member Site
  As a user
  I want to be able to securely authenticate with the Member Portal
  In order to access my bank's information.

Scenario: User logs in
  Given I visit the root path
  When I log in as "local" with password "development"
  Then I should see dashboard modules

Scenario: User logs out
  Given I am logged in as "local" with password "development"
  When I log out
  Then I should see the login form
  When I visit the dashboard
  Then I should see the login form

Scenario: User has wrong password
  Given I visit the root path
  When I log in as "local" with password "badpassword"
  Then I should see a bad login error

Scenario: User has wrong username
  Given I visit the root path
  When I log in as "baduser" with password "development"
  Then I should see a bad login error