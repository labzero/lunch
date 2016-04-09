@jira-mem-1400
Feature: Visiting the Profile Report Page
  As a user
  I want to use visit the profile report page for the FHLB Member Portal
  In order to find out an overall picture of a banks position

Background:
  Given I am logged in as a "extended info user"

@smoke @jira-mem-1400 @flip-on-report-profile
Scenario: Visit profile report page page from the url
  Given I visit the dashboard
  When I am on the "Profile" report page
  Then I should see 12 report tables