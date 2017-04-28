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