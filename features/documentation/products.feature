Feature: Products Page
  As a user
  I want to learn more about the products offered by FHLB
  In order to decide which ones are right for my bank

  Background:
    Given I am logged in

  @smoke
  Scenario: Member navigates to the products pages via the resources dropdown
    Given I hover on the products link in the header
    When I click on the products summary link in the header
    Then I should see the "products summary" product page
    When I hover on the products link in the header
    And I click on the frc link in the header
    Then I should see the "frc" product page
    When I hover on the products link in the header
    And I click on the frc embedded link in the header
    Then I should see the "frc embedded" product page