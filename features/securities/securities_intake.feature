@flip-on-securities
Feature: Securities Intake
  As a user
  I want to pledge or safekeep new securities

  Background:
    Given I am logged in

  @jira-mem-1677 @jira-mem-1873
  Scenario Outline: Member views edit securities instructions
    Given I am on the <page> page
    When I click on the Learn How link
    Then I should see instructions on how to upload securities
    And I should see the contact information for <contact>
    When I click on the Learn How link
    Then I should not see instructions on how to upload securities
  Examples:
  | page                | contact               |
  | safekeep securities | Securities Services   |
  | pledge securities   | Collateral Operations |

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
  | safekeep      | Safekeep Securities |
  | pledge        | Pledge Securities   |

  @jira-mem-1672 @data-unavailable
  Scenario Outline: A user submits a safekeep request for authorization.
    Given I am on the <security_type> securities page
    When I upload a securities intake file
    Then I should see a report table with multiple data rows
    When I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I submit the securities request for authorization
    Then I should see the title for the "<success_page>" success page
  Examples:
  | security_type | success_page     |
  | safekeep      | safekept intake |
  | pledge        | pledge intake   |

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
    Then I should see the title for the "<success_page>" success page
  Examples:
  | security_type | success_page     |
  | safekeep      | safekept intake |
  | pledge        | pledge intake   |

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

  @jira-mem-1791 @data-unavailable
  Scenario Outline: Member uploads a securities release file that has Settlement Amounts and the request has a settlement type of Free
    Given I am on the <security_type> securities page
    And the settlement type is set to Free
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I upload a securities intake file with "settlement amounts"
    When I click to submit the request
    Then I should see the "settlement amount present" error
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1791 @data-unavailable
  Scenario Outline: Member uploads a securities release file that has Settlement Amounts and the request has a settlement type of Vs. Payment
    Given I am on the <security_type> securities page
    And the settlement type is set to Vs Payment
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I upload a securities intake file with "settlement amounts"
    When I click to submit the request
    Then I should see the title for the "<success_page>" success page
  Examples:
  | security_type | success_page     |
  | safekeep      | safekept intake |
  | pledge        | pledge intake   |

  @jira-mem-1792 @data-unavailable
  Scenario Outline: Member uploads a securities release file that has at least one security with an Original Par over the Federal Limit of 50,000,000
    Given I am on the <security_type> securities page
    And I upload a securities intake file with "an original par over the federal limit"
    And I select "Fed" as the release delivery instructions
    And I fill in the "clearing_agent_fed_wire_address_1" securities field with "23454343"
    And I fill in the "clearing_agent_fed_wire_address_2" securities field with "5683asdfa"
    And I fill in the "aba_number" securities field with "5683asdfa"
    And I fill in the "fed_credit_account_number" securities field with "5683asdfa"
    When I click to submit the request
    Then I should see the "over federal limit" error
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1787
  Scenario Outline: Member changes trade and settlement dates
    Given I am on the <security_type> securities page
    When I click the trade date datepicker
    Then I should see that weekends have been disabled
    And I click the datepicker cancel button
    When I click the settlement date datepicker
    Then I should see that weekends have been disabled
    And I should see that all past dates have been disabled
    And I should not be able to see a calendar more than 3 months in the future
    And I click the datepicker cancel button
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1678 @jira-mem-1875 @jira-mem-1876
  Scenario Outline: Member interacts with the Delete Release flyout dialogue
    Given I am on the <security_type> securities page
    When I click the button to delete the request
    Then I should see the delete release flyout dialogue
    And I should see <security_type> copy for the delete flyout
    When I click on the button to continue with the release
    Then I should not see the delete release flyout dialogue
    When I click the button to delete the request
    And I confirm that I want to delete the request
    Then I should be on the Manage Securities page
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1889 @jira-mem-1894 @data-unavailable
  Scenario Outline: A user discards the securities and is not able to submit the form
    Given I am on the <security_type> securities page
    When I upload a securities intake file
    Then I should see a report table with multiple data rows
    When I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    Then the Submit action is enabled
    When I discard the uploaded securities
    Then the Submit action is disabled
  Examples:
  | security_type |
  | safekeep      |
  | pledge        |

  @jira-mem-1874 @data-unavailable
  Scenario Outline: Member uploads a securities intake file and sees the success message
    Given I am on the <page> page
    When I upload a securities intake file with "no settlement amounts"
    Then I should see the securities upload success message
    When I discard the uploaded securities
    Then I should not see the securities upload success message
  Examples:
  | page                |
  | safekeep securities |
  | pledge securities   |

  @jira-mem-1894 @allow-rescue @local-only @data-unavailable
  Scenario Outline: A member submits a request for transfer and there is a general API error
    Given I am on the <page> securities page
    When I upload a securities intake file
    And I fill in the "clearing_agent_participant_number" securities field with "23454343"
    And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
    And I submit the request and the API returns a 500
    Then I should see the "generic catchall" error
  Examples:
  | page      |
  | safekeep  |
  | pledge    |
