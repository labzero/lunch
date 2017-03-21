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

  @jira-mem-2114 @local-only
  Scenario: Admins can enable a feature for everyone
    Given I am logged into the admin panel
    And the feature "test-feature" is disabled
    When I am on the features list
    And I click on the view feature link for "test-feature"
    Then I see an enable feature button
    When I enable the feature
    Then I see the feature enabled for everyone

  @jira-mem-2114 @local-only
  Scenario: Admins can disable a feature for everyone
    Given I am logged into the admin panel
    And the feature "test-feature" is enabled
    When I am on the features list
    And I click on the view feature link for "test-feature"
    Then I see an disable feature button
    When I disable the feature
    Then I see the feature disabled for everyone

  @jira-mem-2115 @local-only
  Scenario: Admins can enable a feature for a member
    Given I am logged into the admin panel
    And the feature "test-feature" is disabled
    When I am on the features list
    And I click on the view feature link for "test-feature"
    Then I see an add institution button
    When I add the institution "Chaste Manhattan"
    Then I see the feature conditionally enabled
    And I see "Chaste Manhattan" in the enabled institution list

  @jira-mem-2115 @local-only
  Scenario: Admins can remove a member from a features list of enabled institutions
    Given I am logged into the admin panel
    And the feature "test-feature" is conditionally enabled for the "Chaste Manhattan" institution
    When I am on the features list
    And I click on the view feature link for "test-feature"
    Then I see a remove institution button
    When I remove the institution "Chaste Manhattan"
    Then I do not "Chaste Manhattan" in the enabled institution list