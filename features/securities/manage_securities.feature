@flip-on-securities
Feature: Managing Securities
  As a user
  I want to visit the Manage Securities page
  In order to manage my securities

Background:
  Given I am logged in

@smoke @jira-mem-1295
Scenario: Visit Manage Securities from the header
  Given I visit the dashboard
  When I hover on the securities link in the header
  When I click on the manage securities link in the header
  Then I should be on the Manage Securities page
  Then I should see a report table with multiple data rows

@jira-mem-1587
Scenario: Member filters securities
  Given I am on the manage securities page
  When I filter the securities by Safekept
  Then I should only see Safekept rows in the securities table
  When I filter the securities by Pledged
  Then I should only see Pledged rows in the securities table

@jira-mem-1587
Scenario: Active state of Release Button
  When I am on the manage securities page
  Then the release securities button should be inactive
  When I check the 1st Pledged security
  Then the release securities button should be active
  When I check the 2nd Pledged security
  Then the release securities button should be active
  When I check the 1st Safekept security
  Then the release securities button should be inactive
  When I uncheck the 1st Safekept security
  Then the release securities button should be active
  When I check the 1st Safekept security
  Then the release securities button should be inactive
  When I uncheck the 1st Pledged security
  Then the release securities button should be inactive
  When I uncheck the 2nd Pledged security
  Then the release securities button should be active