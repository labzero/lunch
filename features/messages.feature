Feature: Visiting the Messages Page
  As a user
  I want to use visit the messages page for the FHLB Member Portal
  In order to view corporate communications

Scenario: Visit the messages page from the header
  Given I visit the dashboard
  When I click on the messages icon in the header
  Then I should see "Categories" as the sidebar title
    And I should see a list of message categories in the sidebar
    And I should see "Messages" as the page's title