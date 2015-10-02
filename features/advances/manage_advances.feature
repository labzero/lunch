@jira-mem-535
Feature: Visiting the Manage Advances Page
  As a user
  I want to use visit the Manage Advances page for the FHLB Member Portal
  In order to view the details of my active advances

Background:
  Given I am logged in

@smoke @jira-mem-535
Scenario: Visit  Manage Advances Page from header link
  Given I visit the dashboard
  When I click on the advances link in the header
  Then I should see active advances data
  And I should see a advances table with multiple data rows

@data-unavailable @jira-mem-535 @jira-mem-1053
Scenario: No data is available to show in the Manage Advances Page
  Given I am on the "Manage Advances" advances page
  When the "Manage Advances" table has no data
  Then I should see an empty report table with No Records messaging