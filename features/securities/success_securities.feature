@flip-on-securities
Feature: Securities Requests Success
  As a user
  I see the Securities Requests Success page
  In order to email authorized signers Authorization Requests

  Background:
    Given I am logged in

  @jira-mem-1595 @jira-mem-1671
  Scenario Outline: Member visits the success page when submitting a securities request
    Given I am on the <page> securities page
    Then I should see the title for the "<page>" page
    And I should see a list of securities authorized users
  Examples:
    | page             |
    | release success  |
    | safekeep success |
    | pledge success   |
    | transfer success   |
