
Feature: Visiting Homepage
  As a user
  I want to use visit the FHLB Member Portal
  In order to find information

  Scenario: Visit homepage
    When I visit the root path
    Then I should see "Welcome aboard You’re riding Ruby on Rails!"