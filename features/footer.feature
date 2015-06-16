
Feature: Viewing the Footer
  As a user
  I want to see the footer on the bottom on the Member Portal
  In order to find information and navigate

  Background:
    Given I am logged out

  Scenario: Viewing the footer
    When I visit the root path
    Then I should see "Federal Home Loan Bank of San Francisco"
    And I should see "Contact"
    And I should see "Terms of Use"
    And I should see "Privacy Policy"
    And I should see "fhlbsf.com"
