@jira-mem-69
Feature: Visiting the Authorizations Report Page
  As a user
  I want to use visit the authorizations report page for the FHLB Member Portal
  In order to view the authorizations granted to all of my bank's users

Background:
  Given I am logged in

@resque-backed @smoke @jira-mem-585 @jira-mem-836
Scenario: Visit authorizations page from header link
  Given I visit the dashboard
  When I select "Authorizations" from the reports dropdown
  And I wait for the report to load
  Then I should see a report table with multiple data rows

@resque-backed @jira-mem-585 @jira-mem-836
Scenario: Filtering the authorization report
  Given I am on the "Authorizations" report page
  And I wait for the report to load
  When I select "Resolution and Authorization" from the authorizations filter
  Then I should only see users with the "Resolution and Authorization" role
  When I select "Entire Authority" from the authorizations filter
  Then I should only see users with the "Entire Authority" role
  When I select "Advances" from the authorizations filter
  Then I should only see users with the "Advances" role
  When I select "Affordable Housing Program" from the authorizations filter
  Then I should only see users with the "Affordable Housing Program" role
  When I select "Collateral" from the authorizations filter
  Then I should only see users with the "Collateral" role
  When I select "Money Market Transactions" from the authorizations filter
  Then I should only see users with the "Money Market Transactions" role
  When I select "Interest Rate Derivatives" from the authorizations filter
  Then I should only see users with the "Interest Rate Derivatives" role
  When I select "Securities Services" from the authorizations filter
  Then I should only see users with the "Securities Services" role
  When I select "Wire Transfer Services" from the authorizations filter
  Then I should only see users with the "Wire Transfer Services" role
  When I select "Access Manager" from the authorizations filter
  Then I should only see users with the "Access Manager" role
  When I select "eTransact Holder" from the authorizations filter
  Then I should only see users with the "eTransact Holder" role
  When I select "User" from the authorizations filter
  Then I should only see users with the "User" role