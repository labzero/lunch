@jira-mem-69
Feature: Visiting the Putable Advance Parallel Shift Sensitivity Analysis Report
  As a user
  I want to use visit the Putable Advance Parallel Shift Sensitivity Analysis Report page for the FHLB Member Portal
  In order to view FHLB's analysis of my bank's putable advances parallel shift sensitivity

Background:
Given I am logged in

@smoke @jira-mem-547
Scenario: Visit putable advances parallel shift sensitivity analysis report page from header link
  Given I visit the dashboard
  When I select "Putable Advance Parallel Shift Sensitivity" from the reports dropdown
  Then I should see a report table with multiple data rows
  And I should see a report header

@data-unavailable @jira-mem-283 @jira-mem-1053
Scenario: No data is available to show in the putable advances parallel shift sensitivity analysis report
  Given I am on the "Putable Advance Parallel Shift Sensitivity" report page
  When the "Putable Advance Parallel Shift Sensitivity" table has no data
  Then I should see an empty report table with No Records messaging

@data-unavailable @jira-mem-282 @jira-mem-1053
Scenario: The putable advances parallel shift sensitivity analysis report has been disabled
  Given I am on the "Putable Advance Parallel Shift Sensitivity" report page
  When the "Putable Advance Parallel Shift Sensitivity" report has been disabled
  Then I should see an empty report table with Data Unavailable messaging