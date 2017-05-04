Feature: Viewing/Modifying the Add Advance Availability settings
  As an Admin
  I want to be able to view and control the availability of advances
  So I can easily discern what the current availability is and change it accordingly

  Background:
    Given I am logged into the admin panel

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
  Scenario: Viewing Add Advance Availability by member
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by member tab
    Then I should see a report table with multiple data rows

  @jira-mem-2200
  Scenario: Viewing the Advance Availability by Term page as a non-admin intranet user
    Given I am logged into the admin panel but do not have web admin privileges
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by term tab
    Then I should see 4 report tables with multiple data rows
    And I should see the advance availability by term page in its view-only mode

  @jira-mem-2201
  Scenario: Viewing and manipulating the Advance Availability by Term page as an admin
    When I click on the trade credit rules link in the header
    And I click on the add advance availability link in the header
    And I click on the add advance availability by term tab
    Then I should see 4 report tables with multiple data rows
    And I should see the advance availability by term page in its editable mode
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