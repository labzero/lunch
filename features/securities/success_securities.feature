@flip-on-securities
Feature: Securities Requests Success
  As a user
  I see the Securities Requests Success page
  In order to email authorized signers Authorization Requests

  Background:
    Given I am logged in

  @jira-mem-1595
  Scenario: Visit account success securities page
    Given I am on the success securities page
    Then I should see a list of securities authorized users
