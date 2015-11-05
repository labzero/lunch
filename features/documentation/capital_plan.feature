Feature: Capital Plan Page
  As a user
  I want to see Bank capital plan
  In order to understand how the Bank capital plan works

Background:
  Given I am logged in

@smoke
Scenario: Member navigates to the guides capital plan via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the capital plan link in the header
  Then I should see the capital plan redemption