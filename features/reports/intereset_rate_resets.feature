@jira-mem-69 @wip
Feature: Visiting the Interest Rate Resets Report Page
  As a user
  I want to use visit the interest rate resets report page for the FHLB Member Portal
  In order to view interest rate resets (rates)

Background:
  Given I am logged in

@smoke @jira-mem-544
Scenario: Visit interest rate resets from header link
  Given I visit the dashboard
  When I select "Interest Rate Resets" from the reports dropdown
  Then I should see "Interest Rate Resets"
  And I should see a report header
  And I should see a report table with multiple data rows

@smoke @jira-mem-544
Scenario: Visiting the Interest Rate Resets Report Page
  Given I am on the "Interest Rate Resets" report page
  Then I should see "The Bank processed the following interest rate resets effective"
  And I should see Interest Rate Resets report
