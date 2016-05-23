@flip-on-securities
Feature: Using the Securities tab
  As a user
  I want to use the Securities tab
  To visit the old FHLB web-site

Background:
  Given I am logged in

@smoke @jira-mem-1295
Scenario: Visit Manage Securities from the header
  Given I visit the dashboard
  When I hover on the securities link in the header
  When I click on the manage securities link in the header
  Then I should be on the Manage Securities page
  Then I should see a report table with multiple data rows

@smoke @jira-mem-1596
Scenario: Visit Securities Requests from the header
  Given I visit the dashboard
  When I hover on the securities link in the header
  When I click on the securities requests link in the header
  Then I should be on the Securities Requests page
  Then I should see two securities requests tables with data rows