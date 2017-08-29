Feature: Viewing/Modifying the Add Advance Availability settings
  As an Etransact Admin
  I want to be able to view and control the availability of advances
  So I can easily discern what the current availability is and change it accordingly

  Background:
    Given I am logged into the admin panel as an etransact admin

  @jira-mem-2186
  Scenario Outline: Navigating to the Add Advance Availability <page_type> page from the admin nav
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability <page_type> tab
    Then I should be on the add advance availability <page_type> page
    And the add advance availability <page_type> tab should be active
  Examples:
    | page_type |
    | status    |
    | by term   |
    | by member |

  @jira-mem-2220
  Scenario: Viewing Add Advance Availability by member as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by member tab
    Then I should see a report table with multiple data rows
    And I should see the advance availability by member page in its view-only mode

  @jira-mem-2594
  Scenario: Viewing Add Advance Availability by member as an admin intranet user without etransact admin privileges
    Given I am logged into the admin panel
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by member tab
    Then I should see a report table with multiple data rows
    And I should see the advance availability by member page in its view-only mode

  @jira-mem-2220
  Scenario: Viewing Add Advance Availability by member as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by member tab
    Then I should see a report table with multiple data rows
    And I should see the advance availability by member page in its view-only mode

  @jira-mem-2197 @jira-mem-2333
  Scenario: Viewing and manipulating the Add Advance Availability by member page as an admin
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by member tab
    Then I should see a report table with multiple data rows
    And I should see the advance availability by member page in its editable mode
    And I should see the advance availability by member submit button disabled
    When I click on the checkbox to toggle the advance availability state of the first member
    Then I should see the advance availability by member submit button enabled
    When I click on the checkbox to toggle the advance availability state of the first member
    And I should see the advance availability by member submit button disabled

  @jira-mem-2197 @local-only
  Scenario: Successfully submitting the form to toggle Add Advance Availability by member
    Given I am on the advance availability by member admin page
    When I click on the checkbox to toggle the advance availability state of the first member
    And I submit the form for advance availability by member
    Then I should see the success message on the advance availability by member page

  @jira-mem-2197 @local-only
  Scenario: Submitting the form to toggle Add Advance Availability by member and receiving an error
    Given I am on the advance availability by member admin page
    When I click on the checkbox to toggle the advance availability state of the first member
    And I submit the form for advance availability by member and there is an error
    Then I should see the error message on the advance availability by member page

  @jira-mem-2196
  Scenario Outline: Filtering Add Advance Availability by <filter> members
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    When I click on the add advance availability by member tab
    And I select the <filter> filter from the advance availability by member dropdown
    Then I should see <filter> members in the advance availability by member table
  Examples:
    | filter   |
    | enabled  |
    | disabled |
    | all      |

  @jira-mem-2200
  Scenario: Viewing the Advance Availability by Term page as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by term tab
    Then I should see 4 report tables with multiple data rows
    And I should see the advance availability by term page in its view-only mode

  @jira-mem-2201 @jira-mem-2203
  Scenario: Viewing and manipulating the Advance Availability by Term page as an admin
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by term tab
    Then I should see 4 report tables with multiple data rows
    And I should see the advance availability by term page in its editable mode
    And I should see the advance availability by term submit button disabled
    When I click on the first checkbox in the vrc section of the advance availability by term form
    Then I should see the advance availability by term submit button enabled
    When I click on the first checkbox in the vrc section of the advance availability by term form
    And I should see the advance availability by term submit button disabled
    When I press the button to uncheck all checkboxes for the availability by term form
    Then I should see only unchecked checkboxes for the availability by term form
    When I press the button to check all checkboxes for the availability by term form
    Then I should see only checked checkboxes for the availability by term form
    When I press the button to uncheck all checkboxes for the availability by term vrc section
    Then I should see only unchecked checkboxes for the availability by term vrc section
    When I press the button to check all checkboxes for the availability by term vrc section
    Then I should see only checked checkboxes for the availability by term vrc section
    When I press the button to uncheck all checkboxes for the availability by term frc short section
    Then I should see only unchecked checkboxes for the availability by term frc short section
    When I press the button to check all checkboxes for the availability by term frc short section
    Then I should see only checked checkboxes for the availability by term frc short section
    When I press the button to uncheck all checkboxes for the availability by term frc long section
    Then I should see only unchecked checkboxes for the availability by term frc long section
    When I press the button to check all checkboxes for the availability by term frc long section
    Then I should see only checked checkboxes for the availability by term frc long section

  @jira-mem-2205
  Scenario: The Add Advance Availability status page is the default Add Advance page in the admin panel
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    Then I should be on the add advance availability status page
    And the add advance availability status tab should be active
    Then I should see the advance availabiltiy status page in its editable mode

  @jira-mem-2205
  Scenario: Viewing the Advance Availability status page as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    Then I should be on the add advance availability status page
    And I should see the advance availabiltiy status page in its view-only mode

  @jira-mem-2206 @local-only
  Scenario: The Add Advance Availability status page is the default Add Advance page in the admin panel
    Given I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I should see the advance availabiltiy status page in its editable mode
    When I click on the button to change the add advance availability status
    Then I should see the success message on the advance availability status page
