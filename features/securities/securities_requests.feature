@flip-on-securities
Feature: Securities Requests
  As a user
  I want to visit the Securities Requests page
  In order to view requests for authorization and authorized requests

Background:
  Given I am logged in

@smoke @jira-mem-1596
Scenario: Visit Securities Requests from the header
  Given I visit the dashboard
  When I hover on the securities link in the header
  When I click on the securities requests link in the header
  Then I should be on the Securities Requests page
  Then I should see two securities requests tables with data rows