Feature: Viewing/Modifying the End of Day Shutoffs for ETransact
  As an Admin
  I want to be able to view and control the end of day shutoffs for ETransact
  So I can easily discern what the current shutoffs are and change them accordingly

  Background:
    Given I am logged into the admin panel

  @jira-mem-2366
  Scenario: Navigating to the Early Shutoffs from the admin nav as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the end of day shutoff link in the header
    Then I should be on the end of day shutoff page
    And the end of day shutoff early shutoffs tab should be active
    And I should see the table of scheduled early shutoffs
    And I should see the end of day shutoff early shutoffs page in its view-only mode

  @jira-mem-2366
  Scenario: Navigating to the Early Shutoffs from the admin nav as an admin
    When I click on the trade credit rules link in the header
    And I click on the end of day shutoff link in the header
    Then I should be on the end of day shutoff page
    And the end of day shutoff early shutoffs tab should be active
    And I should see the table of scheduled early shutoffs
    And I should see the end of day shutoff early shutoffs page in its editable mode

  @jira-mem-2367 @local-only
  Scenario: Scheduling a new early shutoff
    Given I visit the admin early shutoff summary page
    When I click the button to schedule a new early shutoff
    Then I should see the form to schedule a new early shutoff
    When I input "This is a test message" in the field for the early shutoff day of message
    And I click the button to confirm the scheduling of the new early shutoff
    Then I should see the table of scheduled early shutoffs
    And I should see the success message on the advance availability early shutoff page
    When I click the button to schedule a new early shutoff
    And I input "This is a test message" in the field for the early shutoff day of message
    And I click the button to confirm the scheduling of the new early shutoff but there is an error
    Then I should see the error message on the advance availability early shutoff page

  @jira-mem-2375 @local-only
  Scenario: Editing an existing early shutoff
    Given I visit the admin early shutoff summary page
    When I click to edit the first scheduled early shutoff
    Then I should be on the edit page for that early shutoff
    When I input "This is a test message" in the field for the early shutoff day of message
    And I click the button to confirm the scheduling of the edited early shutoff
    Then I should see the success message on the advance availability edit early shutoff page
    When I click to edit the first scheduled early shutoff
    And I click the button to confirm the scheduling of the edited early shutoff but there is an error
    Then I should see the error message on the advance availability early shutoff page

  @jira-mem-2463 @local-only
  Scenario: Removing an existing early shutoff
    Given I visit the admin early shutoff summary page
    When I click to remove the first scheduled early shutoff
    Then I should see the success message on the advance availability remove early shutoff page
    When I click to remove the first scheduled early shutoff but there is an error
    Then I should see the error message on the advance availability early shutoff page

  @jira-mem-2371
  Scenario: Navigating to the Typical Early Shutoffs page from the admin nav as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the end of day shutoff link in the header
    And I click on the end of day shutoff typical shutoffs tab
    Then I should be on the end of day shutoff page
    And the end of day shutoff typical shutoffs tab should be active
    And I should see the end of day shutoff typical shutoffs page in its view-only mode