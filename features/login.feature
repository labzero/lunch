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
Scenario: User not associated with a bank selects a member bank on login
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with a user not associated with a bank
  Then I should see the member bank selector
  And I should see the member bank selector submit button disabled
  When I select the 1st member bank
  Then I should see dashboard modules

@smoke @jira-mem-305
Scenario: User associated with a bank does not sees the select member bank screen
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form
  Then I should see dashboard modules

@smoke @jira-mem-723
Scenario: User sees name in header once logged in
  When I am logged in as a "primary user"
  Then I should see the name for the "primary user" in the header

@jira-mem-502
Scenario: User logs out without selecting a member bank
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with a user not associated with a bank
  Then I should see the member bank selector
  When I log out
  Then I should be logged out

@jira-mem-671 @local-only @first-time-user
Scenario: User accepts the Terms of Service
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with a first-time user
  Then I should see the Terms of Use page
  When I accept the Terms of Use
  Then I should see dashboard modules
  When I log out
  And I visit the root path
  And I fill in and submit the login form with a first-time user
  Then I should see dashboard modules

@jira-mem-1023 @local-only @first-time-user
Scenario: User cannot enter site without accepting the Terms of Use
  Given I am logged out
  And I visit the root path
  And I fill in and submit the login form with a first-time user
  When I visit the dashboard
  Then I should see the Terms of Use page

@jira-mem-1041 @local-only @first-time-user
Scenario: User can log out without accepting the Terms of Use
  Given I am logged out
  And I visit the root path
  And I fill in and submit the login form with a first-time user
  Then I should see the Terms of Use page
  When I do not accept the Terms of Use
  Then I should be logged out

@jira-mem-1163 @local-only @first-time-user
Scenario: User logins are case insensitive
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with a first-time user
  Then I should see the Terms of Use page
  When I accept the Terms of Use
  Then I should see dashboard modules
  When I log out
  And I visit the root path
  And I fill in and submit the login form with the capitalized last user
  Then I should see dashboard modules

@jira-mem-859
Scenario: User logs in with expired password
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with an expired user
  Then I should see the change password form
  When I visit the dashboard
  Then I should see the change password form
  And I should see password change validations
  When I enter a valid new password
  And I submit the form
  Then I should see the change password success page
  When I dismiss the change password success page
  Then I proceed through the login flow
  And I should be logged in
  When I log out
  And I login as the expired user with the new password
  Then I should be logged in

@jira-mem-668
Scenario: User tries to log in as an extranet user without required role
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with an extranet no role user
  Then I should see a bad login error

@local-only @offsite-ip @jira-mem-642
Scenario: User tries to log in as an internal user without external access from an offsite IP
  Given I am logged out
  When I fill in and submit the login form with a primary user
  Then I should see a bad login error

@local-only @offsite-ip @jira-mem-642
Scenario: User logs in as an internal user with external access from an offsite IP
  Given I am logged out
  When I log in as an "offsite user"
  Then I should be logged in

@jira-mem-519
Scenario: User tries to navigate back after logout
  Given I am logged in
  When I log out
  And I use the browser back button
  Then I should see the login form
  
@jira-mem-1123 @smoke
Scenario: User sees the logged out page when logging out
  Given I am logged in
  When I log out
  Then I should see the logged out page
  
Scenario: User is redirected when visiting the logged out page directly
  Given I am logged in
  When I visit the logged out page
  Then I should see dashboard modules

@jira-mem-1018
Scenario: User can change institutions via the link in nav header
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with a user not associated with a bank
  Then I should see the member bank selector
  And I should see the member bank selector submit button disabled
  When I select the 1st member bank
  Then I should see dashboard modules
  When I wait for the dashboard to fully load
  And I click on the switch link in the nav
  Then I should see the member bank selector

@smoke @jira-mem-1401 @flip-on-report-profile
Scenario: Users with the extra info role and without an assigned bank can go to the member's profile from the bank selector 
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with an extended info user
  Then I should see the member bank selector
  And I should see the member profile button disabled
  When I pick a bank
  Then I should see the member profile button enabled
  When I view the member profile from the bank selector
  Then I see the profile report in a new window and close it
  And I should see dashboard modules

@jira-mem-1401 @flip-on-report-profile
Scenario: Users without the extra info role don't see the member profile option when viewing the bank selector
  Given I am logged out
  And I visit the root path
  When I fill in and submit the login form with an intranet user
  Then I should see the member bank selector
  And I should not see the member profile button
