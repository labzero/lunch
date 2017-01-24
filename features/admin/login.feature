Feature: Logging in to the Admin panel
  As an Admin
  I want to log in to the Admin panel
  So I can update the portal configuration

  @jira-mem-2109
  Scenario: Admins can log into the Admin panel without selecting a bank
    Given I am logged out
    And I visit the root path
    When I fill in and submit the login form with an admin user
    And I visit the admin dashboard
    Then I see the admin dashboard

  @jira-mem-2109
  Scenario: Admins can log into the Admin panel without selecting a bank
    Given I am logged out
    And I visit the admin dashboard
    When I fill in and submit the login form with an admin user
    Then I see the admin dashboard

  @jira-mem-2109
  Scenario: Admins are redirected to their initial destination after login and bank selection
    Given I am logged out
    And I visit the settings page
    When I fill in and submit the login form with an admin user
    And I select the 1st member bank
    Then I see the settings page
