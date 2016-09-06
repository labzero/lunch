@flip-on-securities
Feature: Securities Intake
  As a user
  I want to pledge or safekeep new securities

  Background:
    Given I am logged in

  @jira-mem-1677
  Scenario Outline: Member views edit securities instructions
    Given I am on the <page> page
    When I click on the Learn How link
    Then I should see instructions on how to upload securities
    When I click on the Learn How link
    Then I should not see instructions on how to upload securities
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1676 @data-unavailable
  Scenario Outline: Member cancels an upload of a securities intake file
    Given I am on the <page> page
    When I drag and drop the "upload-test-file.txt" file into the edit securities dropzone
    Then I should see an upload progress bar
    When I click to cancel the securities release file upload
    Then I should not see an upload progress bar
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1669
  Scenario Outline: A signer views a previously submitted request
    Given I am logged in as a "quick-advance signer"
    And I am on the securities request page
    When I click to Authorize the first <security_type>
    Then I should be on the <page> page
  Examples:
  | security_type | page                |
  | safekeep      | safekeep securities |
  | pledge        | pledge securities   |

  @jira-mem-1672 @data-unavailable
  Scenario Outline: A user submits a safekeep request for authorization.
    Given I am on the <security_type> securities page
    When I upload a securities intake file
    Then I should see a report table with multiple data rows
    When I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I submit the securities request for authorization
    Then I should see the title for the "<security_type> success" page
  Examples:
    | security_type |
    | safekeep      |
    | pledge        |