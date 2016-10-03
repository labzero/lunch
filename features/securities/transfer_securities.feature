@flip-on-securities
Feature: Transfer Securities
  As a user
  I want to transfer securities between pledged and safekept accounts and vice versa
  In order to manage my accounts

  Background:
    Given I am logged in

  @jira-mem-1734 @jira-mem-1721
  Scenario Outline: View the transferred securities on the Edit Transfer page
    When I am on the manage securities page
    And I check the 1st <security_type> security
    And I remember the cusip value of the 1st <security_type> security
    And I check the 2nd <security_type> security
    And I remember the cusip value of the 2nd <security_type> security
    And I click the button to transfer the securities
    Then I should be on the <page> page
    And I should see a report table with multiple data rows
    And I should see the cusip value from the 1st <security_type> security in the 1st row of the securities table
    And I should see the cusip value from the 2nd <security_type> security in the 2nd row of the securities table
  Examples:
  | security_type  | page                 |
  | Pledged        | Transfer to Safekept |
  | Safekept       | Transfer to Pledged  |

  @jira-mem-1715 @jira-mem-1880
  Scenario Outline: Member views edit securities instructions
    Given I am on the transfer to <page> account securities page
    When I click on the Edit Securities link
    Then I should see instructions on how to edit securities
    And I should see the contact information for <contact>
    When I click on the Edit Securities link
    Then I should not see instructions on how to edit securities
  Examples:
    | page     | contact               |
    | safekept | Collateral Operations |
    | pledged  | Collateral Operations |

  Scenario: Authorized signer views legal copy for pledge transfers
    Given I am logged in as a "quick-advance signer"
    And I am on the manage securities page
    And I check the 1st Safekept security
    When I click the button to transfer the securities
    Then I should see the pledge legal copy

  Scenario: Authorized signer does not view legal copy for safekept transfers
    Given I am logged in as a "quick-advance signer"
    And I am on the manage securities page
    And I check the 1st Pledged security
    When I click the button to transfer the securities
    Then I should not see the pledge legal copy

  @jira-mem-1716 @jira-mem-1874 @data-unavailable
  Scenario Outline: Member uploads an edited securities file that is valid
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I upload a securities transfer file
    And I wait for the securities file to upload
    Then I should see the securities upload success message
    Then I should see an uploaded transfer security with a description of "Zip Zoop Zap"
    And I should see an uploaded transfer security with an original par of "123,456,789.00"
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1714
  Scenario Outline: Member sees success page after submitting transfer for authorization
    Given I am on the transfer to <page> account securities page
    When I submit the securities release request for authorization
    Then I should see the title for the "transfer" success page
  Examples:
  | page     |
  | pledged  |
  | safekept |

  @jira-mem-1739
  Scenario Outline: A signer authorizes a request while submitting it
    Given I am logged in as a "quick-advance signer"
    And I am on the transfer to <page> account securities page
    When I authorize the request
    Then I should see the authorize request success page
  Examples:
  | page     |
  | pledged  |
  | safekept |

  @jira-mem-1719 @jira-mem-1894 @allow-rescue @local-only
  Scenario Outline: A member submits a request for transfer and there is a general API error
    Given I am on the transfer to <page> account securities page
    When I submit the request and the API returns a 500
    Then I should see the "generic catchall" error
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1742 @jira-mem-1878
  Scenario Outline: Member interacts with the Delete Request flyout dialogue
    Given I am on the transfer to <page> account securities page
    When I click the button to delete the request
    Then I should see the delete release flyout dialogue
    And I should see <delete_dialogue> copy for the delete flyout
    When I click on the button to continue with the release
    Then I should not see the delete release flyout dialogue
    When I click the button to delete the request
    And I confirm that I want to delete the request
    Then I should be on the Manage Securities page
  Examples:
    | page     | delete_dialogue |
    | pledged  | transfer        |
    | safekept | transfer        |

  @jira-mem-1743 @data-unavailable
  Scenario: A signer edits a previously submitted request
    Given I am logged in as a "quick-advance signer"
    And I am on the securities request page
    When I click to Authorize the first transfer
    Then I should be on the Transfer Securities page
    When I click on the Edit Securities link
    When I upload a securities transfer file
    And I wait for the securities file to upload
    Then I should see an uploaded transfer security with a description of "Zip Zoop Zap"
    And I should see an uploaded transfer security with an original par of "123,456,789.00"

  @jira-mem-1900 @data-unavailable
  Scenario Outline: Member uploads a securities transfer file that is missing Original Par
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I drag and drop the "transfer_securities_missing_original_par.xlsx" file into the edit securities dropzone
    Then I should see an original par blank field error
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1900 @data-unavailable
  Scenario Outline: Member uploads a securities transfer file that is missing a CUSIP
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I drag and drop the "transfer_securities_missing_cusip.xlsx" file into the edit securities dropzone
    Then I should see a security required field error
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1900 @data-unavailable
  Scenario Outline: Member sees an error when uploading an transfer file with no valid rows
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I drag and drop the "transfer_securities_no_rows.xlsx" file into the edit securities dropzone
    Then I should see a no securities field error
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1900 @data-unavailable
  Scenario Outline: Member uploads a securities transfer file that has an invalid Original Par
    Given I am on the transfer to <page> account securities page
    And the edit securities section is open
    When I drag and drop the "transfer_securities_invalid_original_par.xlsx" file into the edit securities dropzone
    Then I should see an original par numericality field error
  Examples:
    | page     |
    | pledged  |
    | safekept |

  @jira-mem-1897
  Scenario Outline: Intranet users are not allowed to submit an intake request
    Given I log in as an "intranet user"
    And I am on the transfer to <page> account securities page
    When I submit the securities request for authorization
    Then I should see the "intranet user" error
  Examples:
    | page     |
    | pledged  |
    | safekept |