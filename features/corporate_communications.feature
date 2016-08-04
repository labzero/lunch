@flip-on-announcements
Feature: Visiting the Messages Page
  As a user
  I want to use visit the messages page for the FHLB Member Portal
  In order to view corporate communications

  Background:
    Given I am logged in

@smoke
Scenario: Visit the messages page from the header
  Given I visit the dashboard
  When I click on the announcements icon in the header
  Then I should see "Filters" as the sidebar title
    And I should see a list of message categories in the sidebar
    And I should see "Announcements" as the page's title

Scenario: Filtering by message type
  Given I am on the Messages page
  When I select the "Shareholder Communications / Investor Relations" filter in the sidebar
  Then I should see the active state for the "Shareholder Communications / Investor Relations" sidebar item
  When I select the first message on the messages page
  Then I should see the active state for the "Shareholder Communications / Investor Relations" sidebar item
  When I select the "Collateral" filter in the sidebar
  Then I should see the active state for the "Collateral" sidebar item
  When I select the first message on the messages page
  Then I should see the active state for the "Collateral" sidebar item

Scenario: View the details of a message
  Given I am on the Messages page
  When I select the first message on the messages page
  Then I should be see the message detail view

Scenario: Navigate from one detail page to another
  Given I am on the Messages page
  And I remember all the message titles
  When I select the first message on the messages page
  Then I should be see the message detail view
  When I click on the "Older" link at the top of the message detail view
  Then I see the title of the second message
  When I click on the "Newer" link at the top of the message detail view
  Then I see the title of the first message

@jira-mem-923
Scenario: View messages with attachments
  Given I am on the Messages page
  When I click on a message with attachments
  Then I should see a list of attachments

@data-unavailable @jira-mem-288
Scenario: No messages in any category
  Given I am on the Messages page
  When the "Messages" table has no data
  Then I should see a No Messages indicator

@data-unavailable @jira-mem-288
Scenario: No messages in "Collateral" category
  Given I am on the Messages Page
  When the "Collateral Pledging" category has no messages
  Then "Collateral Pledging" category should be disabled

@local-only @jira-mem-1240
Scenario: User is alerted when there are new messages
  When I have a new message
  And I am logged in
  Then I should see an announcements icon in the header with a badge indicating I have new messages
  When I click on the announcements icon in the header
  Then I should see an announcements icon in the header with no badge