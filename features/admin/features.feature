Feature: Toggling conditional features
  As an Admin
  I want to be able to control the conditional features
  So I can incrementally roll a feature out to the members

  @jira-mem-2111
  Scenario: Admins can log into the Admin panel without selecting a bank
    Given I am logged into the admin panel
    When I click on the test features link in the header
    And I click on the features link in the header
    Then I see a list of features and their state