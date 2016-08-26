@flip-on-securities
Feature: Securities Requests
  As a user
  I want to visit the Securities Requests page
  In order to view requests for authorization and authorized requests

Background:
  Given I am logged in

@smoke @jira-mem-1596
Scenario: Visit Securities Requests from the header
  Given I visit the dashboard
  When I hover on the securities link in the header
  When I click on the securities requests link in the header
  Then I should be on the Securities Requests page
  Then I should see two securities requests tables with data rows

@jira-mem-1597
Scenario: Non-securities signer does not see active Authorize links
  When I am on the securities request page
  Then I should a disabled state for the Authorize action

@jira-mem-1597
Scenario: Securities signer navigates to view a release request from the Securities Requests page
  Given I am logged in as a "quick-advance signer"
  When I am on the securities request page
  Then I should an active state for the Authorize action
  When I click to Authorize the first release
  Then I should be on the Securities Release page

  @jira-mem-1599 @jira-mem-1667
  Scenario Outline: A signer authorizes a previously submitted request
    Given I am logged in as a "quick-advance signer"
    And I am on the securities request page
    When I click to Authorize the first <request_type>
    Then I should be on the <page> page
    When I choose the first available date for trade date
    And I choose the first available date for settlement date
    And I authorize the request
    Then I should see the authorize request success page
  Examples:
    | request_type | page                |
    | release      | Securities Release  |
    | pledge       | Pledge Securities   |
    | safekeep     | Safekeep Securities |
