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
    When I drag and drop the "upload-test-file.txt" file into the upload securities dropzone
    Then I should see an upload progress bar
    When I click to cancel the securities release file upload
    Then I should not see an upload progress bar
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1781 @data-unavailable
  Scenario Outline: Member uploads a securities intake file that is missing Original Par
    Given I am on the <page> page
    When I drag and drop the "intake_securities_missing_original_par.xlsx" file into the upload securities dropzone
    Then I should see a security required field error
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1781 @data-unavailable
  Scenario Outline: Member uploads a securities intake file that is missing a CUSIP
    Given I am on the <page> page
    When I drag and drop the "intake_securities_missing_cusip.xlsx" file into the upload securities dropzone
    Then I should see a security required field error
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1779 @data-unavailable
  Scenario Outline: Member sees an error when uploading an intake file with no valid rows
    Given I am on the <page> page
    When I drag and drop the "intake-securities-no-rows.xlsx" file into the upload securities dropzone
    Then I should see a no securities field error
  Examples:
    | page                |
    | safekeep securities |
    | pledge securities   |

  @jira-mem-1783 @data-unavailable
  Scenario Outline: Member uploads a securities intake file that has an invalid Original Par
    Given I am on the <page> page
    When I drag and drop the "intake_securities_invalid_original_par.xlsx" file into the upload securities dropzone
    Then I should see an original par numericality field error
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

  @jira-mem-1786 @data-unavailable
  Scenario Outline: Member selects a settlement date that occurs before the trade date
    Given I am on the <security_type> securities page
    And I choose the first available date for settlement date
    And I choose the last available date for trade date
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I upload a securities intake file
    When I click to submit the request
    Then I should see the "settlement date before trade date" error
  Examples:
    | security_type |
    | safekeep      |
    | pledge        |

  @jira-mem-1790 @data-unavailable
  Scenario Outline: Member uploads a securities release file that is missing Settlement Amount and the request has a settlement type of Free
    Given I am on the <security_type> securities page
    And the settlement type is set to Free
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I upload a securities intake file with "no settlement amounts"
    When I click to submit the request
    Then I should see the title for the "<security_type> success" page
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1790 @data-unavailable
  Scenario Outline: Member uploads a securities release file that is missing Settlement Amount and the request has a settlement type of Vs. Payment
    Given I am on the <security_type> securities page
    And the settlement type is set to Vs Payment
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I upload a securities intake file with "no settlement amounts"
    When I click to submit the request
    Then I should see the "settlement amount required" error
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |