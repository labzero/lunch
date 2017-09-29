@flip-on-mortgages
Feature: Requesting a New Mortgage Collateral Update
  As a user
  I want to request a New Mortgage Collateral Update
  In order to extend the credit options available to my bank

  Background:
    Given I am logged in as a "collateral signer"

  @jira-mem-2574
  Scenario Outline: Accessing the Mortgage Collateral Update flow
    Given I am logged in as a "<user_type>"
    When I visit the dashboard
    Then I <permission> see the Mortgage Collateral Update dropdown menu in the header
    Examples:
      | user_type                | permission |
      | collateral signer        | should     |
      | intranet user            | should     |
      | quick-advance non-signer | should not |

  @jira-mem-2574
  Scenario: Visiting the New Mortgage Collateral Update (MCU) page
    Given I visit the dashboard
    When I click on the mortgages link in the header
    And I click on the new mortgage collateral update link in the header
    Then I should see the active state of the mortgages nav item
    And I should see the mcu file upload area

  @jira-mem-2574
  Scenario: Interacting with the New Mortgage Collateral Update dropdown selectors
    When I am on the new mortgage collateral update page
    Then I should see the enabled state of the pledge type dropdown
    And I should see the disabled state of the mcu type dropdown
    And I should see the disabled state of the program type dropdown
    And I should not see any mcu legal copy
    When I click on the pledge type dropdown
    And I select "Specific Identification" from the pledge type dropdown
    Then I should see the enabled state of the mcu type dropdown
    And I should see the disabled state of the program type dropdown
    And I should see specific identification mcu legal copy
    And I should not see blanket lien mcu legal copy
    When I click on the mcu type dropdown
    Then I should see "Complete" as an option in the mcu type dropdown
    And I should see "Update" as an option in the mcu type dropdown
    And I should see "Pledge" as an option in the mcu type dropdown
    And I should see "Depledge" as an option in the mcu type dropdown
    And I should see "Renumber" as an option in the mcu type dropdown
    And I should not see "Add" as an option in the mcu type dropdown
    And I should not see "Delete" as an option in the mcu type dropdown
    When I click on the pledge type dropdown
    When I select "Blanket Lien – Detailed Reporting" from the pledge type dropdown
    Then I should not see specific identification mcu legal copy
    And I should see blanket lien mcu legal copy
    When I click on the mcu type dropdown
    Then I should see "Complete" as an option in the mcu type dropdown
    And I should see "Update" as an option in the mcu type dropdown
    And I should see "Add" as an option in the mcu type dropdown
    And I should see "Delete" as an option in the mcu type dropdown
    And I should see "Renumber" as an option in the mcu type dropdown
    And I should not see "Pledge" as an option in the mcu type dropdown
    And I should not see "Depledge" as an option in the mcu type dropdown
    When I select "Complete" from the mcu type dropdown
    Then I should see the enabled state of the program type dropdown
    When I click on the pledge type dropdown
    And I select "Specific Identification" from the pledge type dropdown
    Then I should see the enabled state of the mcu type dropdown
    And I should see the disabled state of the program type dropdown
