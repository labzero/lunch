Feature: Global header
  As a user
  I want to use the global header
  In order to navigate the site

Background:
  Given I am logged in

Scenario: Member sees reports dropdown
  Given I visit the dashboard
  And I don't see the reports dropdown
  When I hover on the reports link in the header
  Then I should see the reports dropdown

Scenario: Member sees resources dropdown
  Given I visit the dashboard
  And I don't see the resources dropdown
  When I hover on the resources link in the header
  Then I should see the resources dropdown