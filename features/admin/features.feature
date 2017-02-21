Feature: Toggling conditional features
  As an Admin
  I want to be able to control the conditional features
  So I can incrementally roll a feature out to the members

  @jira-mem-2111
  Scenario: Admins see a list of features and their availability
    Given I am logged into the admin panel
    When I click on the test features link in the header
    And I click on the features link in the header
    Then I see a list of features and their state

  @jira-mem-2112
  Scenario: Admins can view a feature to see who its enabled for
    Given I am logged into the admin panel
    When I am on the features list
    And I click on the view feature link
    Then I see a list of enabled members
    And I see a list of enabled users