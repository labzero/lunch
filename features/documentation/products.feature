Feature: Products Page
  As a user
  I want to learn more about the products offered by FHLB
  In order to decide which ones are right for my bank

  Background:
    Given I am logged in

  @smoke
  Scenario: Member navigates to the products summary page via the resources dropdown
    Given I hover on the products link in the header
    When I click on the products summary link in the header
    Then I should see the products summary page