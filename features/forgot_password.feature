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

@local-only @jira-mem-717 @jira-mem-1021
Scenario: Resetting a password
  Given I visit a valid reset password link
  When I enter a password of "abcder12"
  Then I should see a criteria not met required password error
  When I enter a password of "abcder!"
  Then I should see a criteria not met required password error
  When I enter a password of "abcderABC"
  Then I should see a criteria not met required password error
  When I enter a password of "ABCDE@#!"
  Then I should see a criteria not met required password error
  When I enter a password of "ABC83429"
  Then I should see a criteria not met required password error
  When I enter a password of "9467@#!**"
  Then I should see a criteria not met required password error
  When I enter a password of "123Cd3!"
  Then I should see a minimum length required password error
  When I enter a password of "123Abcd3!"
  And I enter a password confirmation of "123Abcd3!"
  Then I should see no password errors
  When I submit the form
  Then I should see the login form
  And I should see a password change success flash
  When I fill in and submit the login form with reset username and password "123Abcd3!"
  Then I should be logged in

@local-only @jira-mem-1068
Scenario: User password confirmation does not match in new password flow
  Given I visit a valid reset password link
  When I enter a password of "123Abcd3!"
  And I focus on the password confirmation field
  Then I should not see a password match error
  When I focus on the new password field
  Then I should not see a password match error
  When I try to submit the form
  Then I should see a password match error
  When I enter a password confirmation of "123Abcd3!"
  And I focus on the new password field
  Then I should not see a password match error
  When I submit the form
  Then I should not see an error flash
