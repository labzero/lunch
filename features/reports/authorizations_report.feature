@flip-on-report-authorizations
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
  And I should see a report header

@resque-backed @jira-mem-585 @jira-mem-836 @jira-mem-1297
Scenario: Filtering the authorization report
  Given I am on the "Authorizations" report page
  And I wait for the report to load
  When I select "Resolution and Authorization" from the authorizations filter
  Then I should only see users with the "Resolution and Authorization" role
  When I select "Entire Authority" from the authorizations filter
  Then I should only see users with the "Entire Authority" role
  When I select "Advances" from the authorizations filter
  Then I should only see users with the "Advances" role or with inclusive roles
  When I select "Affordable Housing Program" from the authorizations filter
  Then I should only see users with the "Affordable Housing Program" role or with inclusive roles
  When I select "Collateral" from the authorizations filter
  Then I should only see users with the "Collateral" role or with inclusive roles
  When I select "Money Market Transactions" from the authorizations filter
  Then I should only see users with the "Money Market Transactions" role or with inclusive roles
  When I select "Interest Rate Derivatives" from the authorizations filter
  Then I should only see users with the "Interest Rate Derivatives" role or with inclusive roles
  When I select "Securities Services" from the authorizations filter
  Then I should only see users with the "Securities Services" role or with inclusive roles
  When I select "Wire Transfer Services" from the authorizations filter
  Then I should only see users with the "Wire Transfer Services" role or with inclusive roles
  When I select "Access Manager" from the authorizations filter
  Then I should only see users with the "Access Manager" role or with inclusive roles

@resque-backed @smoke @jira-mem-824
Scenario: Member downloads a PDF of the Authorizations report
  Given I am on the "Authorizations" report page
  When I request a PDF
  Then I should begin downloading a file

@resque-backed @local-only @jira-mem-1297
Scenario: Member sees Resolution and Authorization users when filtering by a role, even though those users do not explicitly have the filtered role
  Given I am signed in as a Chaste Manhattan user
  And I am on the "Authorizations" report page
  When I select "Collateral" from the authorizations filter
  Then I should see 2 authorized users
  And I should see user "Della Duck" with the "Collateral" authorization and no "Resolution and Authorization" authorization
  And I should see user "Ronald Ruck" with the "Resolution and Authorization" footnoted authorization and no "Collateral" authorization
  When I select "Securities Services" from the authorizations filter
  Then I should see 1 authorized user
  And I should see user "Ronald Ruck" with the "Resolution and Authorization" footnoted authorization and no "Securities Services" authorization