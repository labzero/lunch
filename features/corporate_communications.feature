Feature: Visiting the Messages Page
  As a user
  I want to use visit the messages page for the FHLB Member Portal
  In order to view corporate communications

  Background:
    Given I am logged in

@smoke
Scenario: Visit the messages page from the header
  Given I visit the dashboard
  When I click on the messages icon in the header
  Then I should see "Categories" as the sidebar title
    And I should see a list of message categories in the sidebar
    And I should see "Messages" as the page's title

Scenario: Filtering by message type
  Given I am on the Messages Page
  When I select the "Investor Relations & Disclosure" filter in the sidebar
  Then I should see the active state for the "Investor Relations & Disclosure" sidebar item
    And I should only see "Investor Relations & Disclosure" messages
  When I select the "Credit & Collateral" filter in the sidebar
  Then I should see the active state for the "Credit & Collateral" sidebar item
    And I should only see "Credit & Collateral" messages

Scenario: View the details of a message
  Given I am on the Messages Page
  When I select the first message on the messages page
  Then I should be see the message detail view
