@jira-mem-69
Feature: Visiting the Current Price Indications Report Page
  As a user
  I want to use visit the current price indications report page for the FHLB Member Portal
  In order to view current price indications (rates)

Background:
  Given I am logged in

@smoke @jira-mem-315
Scenario: Visit current price indications from header link
  Given I visit the dashboard
  When I select "Current" from the reports dropdown
  Then I should see "Current Price Indications"
  And I should see a report table with multiple data rows

@smoke @jira-mem-315
Scenario: Visiting the Current Price Indications Report Page
  Given I am on the "Current Price Indications" report page
  Then I should see "Standard Credit Program"
  And I should see "VRC Advance"
  And I should see "FRC Advance"
  And I should see "ARC Advance (Basis Point Spread)"
  And I should see "Securities-Backed Credit"
  And I should see "Settlement/Transaction Account"
  And I should see "General Information"
