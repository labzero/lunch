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
  When I hover on the advances link in the header
  And I click on the manage advances link in the header
  And I wait for the report to load
  Then I should see active advances data
  And I should see a advances table with multiple data rows
  And I should see the "Trade Date" column values in "descending" order

@jira-mem-1578
Scenario: Members filter the Advances list
  Given I am on the "Manage Advances" advances page
  Then I see only outstanding advances
  And  I see the "Outstanding Advances" filter selected
  When I filter the advances by "All Advances"
  Then I see all advances
  And  I see the "All Advances" filter selected
  When I filter the advances by "Outstanding Advances"
  Then I see only outstanding advances
  And  I see the "Outstanding Advances" filter selected

@data-unavailable @jira-mem-535 @jira-mem-1053
Scenario: No data is available to show in the Manage Advances Page
  Given I am on the "Manage Advances" advances page
  When the "Manage Advances" table has no data
  Then I should see an empty report table with No Records messaging

@flip-on-advance-confirmation @jira-mem-567
Scenario: Member sees an advance confirmation column
  When I am on the "Manage Advances" advances page
  Then I should see an Advance Confirmation column in the data table

@jira-mem-1634
Scenario: Member sees an "Add Advance" button if they can take out an advance
  When I am on the "Manage Advances" advances page
  Then I should not see an "Add Advance" button
  When I am logged in as a "quick-advance signer"
  And I am on the "Manage Advances" advances page
  Then I should see an "Add Advance" button