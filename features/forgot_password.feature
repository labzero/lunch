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

@jira-mem-714
Scenario: Requesting a password reset for an unknown user
  Given I visit the root path
  When I follow the forgot password link
  Then I should see the forgot password page
  When I enter an invalid username
  And I submit the form
  Then I should see the forgot password page
  And I should see an unknown user error flash
