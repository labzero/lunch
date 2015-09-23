Feature: Recovering a forgotten password
  As a user
  I want to be able to recover my password
  In order to be able to log back into the site

Background:
  Given I am logged out

@jira-mem-714
Scenario: Requesting a password reset
  Given I visit the root path
  When I follow the forgot password link
  Then I should see the forgot password page
  When I enter my username
  And I submit the form
  Then I should see the forgot password confirmation page

@smoke @jira-mem-714
Scenario: Requesting a password reset for an unknown user
  Given I visit the root path
  When I follow the forgot password link
  Then I should see the forgot password page
  When I enter an invalid username
  And I submit the form
  Then I should see the forgot password page
  And I should see an unknown user error flash

@smoke @jira-mem-716
Scenario: Using an expired/invalid reset password link
  Given I visit the root path
  When I follow an invalid password link
  Then I should see the forgot password request expired page

@local-only @jira-mem-717
Scenario: Resetting a password
  Given I visit a valid reset password link
  When I enter a password of "123abcd3!"
  Then I should see a capital letter required password error
  When I enter a password of "123ABCD3!"
  Then I should see a lowercase required password error
  When I enter a password of "ABCDefGH!"
  Then I should see a number required password error
  When I enter a password of "123Abcd3"
  Then I should see a symbol required password error
  When I enter a password of "123Cd3!"
  Then I should see a minimum length required password error
  When I enter a password of "123Abcd3!"
  Then I should see a confirmation required password error
  When I enter a password confirmation of "123Abcd3!"
  Then I should see no password errors
  When I submit the form
  Then I should see the login form
  And I should see a password change success flash
  When I fill in and submit the login form with reset username and password "123Abcd3!"
  Then I should be logged in
