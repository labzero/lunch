@flip-on-letters-of-credit
Feature: Viewing the sidebars
  As a user
  I want to see sidebars containing relevant information
  In order to assist me in various site flows

  Background:
    Given I am logged in as a "quick-advance signer"

  @jira-mem-2282
  Scenario Outline: Viewing the Borrowing Capacity sidebar
    When <page_step>
    Then I should see a Borrowing Capacity sidebar
    Examples:
    | page_step |
    | I visit the Request Letter of Credit page |
    | I am on the "Add Advance" advances page   |