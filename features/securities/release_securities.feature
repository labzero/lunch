@flip-on-securities
Feature: Releasing Securities
  As a user
  I want to release securities
  In order to pledge them with other institutions or sell them

Background:
  Given I am logged in

@jira-mem-1588
Scenario: View the released securities on the Edit Release
  When I am on the manage securities page
  When I check the 1st Pledged security
  And I remember the cusip value of the 1st Pledged security
  And I check the 2nd Pledged security
  And I remember the cusip value of the 2nd Pledged security
  And I click the button to release the securities
  Then I should see a report table with multiple data rows
  And I should see the cusip value from the 1st Pledged security in the 1st row of the securities table
  And I should see the cusip value from the 2nd Pledged security in the 2nd row of the securities table

@jira-mem-1588
Scenario: View the various Delivery Instructions field sets
  When I am on the release securities page
  Then I should see "DTC" as the selected release delivery instructions
  And I should see the "DTC" release instructions fields
  When I select "Fed" as the release delivery instructions
  Then I should see "Fed" as the selected release delivery instructions
  And I should see the "Fed" release instructions fields
  When I select "Physical" as the release delivery instructions
  Then I should see "Physical" as the selected release delivery instructions
  And I should see the "Physical" release instructions fields
  When I select "Mutual Fund" as the release delivery instructions
  Then I should see "Mutual Fund" as the selected release delivery instructions
  And I should see the "Mutual Fund" release instructions fields

@jira-mem-1592 @jira-mem-1877
Scenario: Member interacts with the Delete Release flyout dialogue
  Given I am on the release securities page
  When I click the button to delete the request
  Then I should see the delete release flyout dialogue
  And I should see release copy for the delete flyout
  When I click on the button to continue with the release
  Then I should not see the delete release flyout dialogue
  When I click the button to delete the request
  And I confirm that I want to delete the request
  Then I should be on the Manage Securities page

@jira-mem-1589 @jira-mem-1879
Scenario Outline: Member views edit securities instructions
  Given I am on the <page> securities page
  When I click on the Edit Securities link
  Then I should see instructions on how to edit securities
  And I should see the contact information for <contact>
  When I click on the Edit Securities link
  Then I should not see instructions on how to edit securities
Examples:
| page             | contact               |
| safekeep release | Securities Services   |
| pledge release   | Collateral Operations |

@jira-mem-1590 @data-unavailable
Scenario: Member cancels an upload of a securities release file
  Given I am on the release securities page
  And the edit securities section is open
  When I drag and drop the "upload-test-file.txt" file into the edit securities dropzone
  Then I should see an upload progress bar
  When I click to cancel the securities release file upload
  Then I should not see an upload progress bar

@jira-mem-1781 @data-unavailable
Scenario: Member uploads a securities release file that is missing Original Par
  Given I am on the release securities page
  And the edit securities section is open
  When I drag and drop the "securities_missing_original_par.xlsx" file into the edit securities dropzone
  Then I should see a security required field error

@jira-mem-1781 @data-unavailable
Scenario: Member uploads a securities release file that is missing a CUSIP
  Given I am on the release securities page
  And the edit securities section is open
  When I drag and drop the "securities_missing_cusip.xlsx" file into the edit securities dropzone
  Then I should see a security required field error

@jira-mem-1779 @data-unavailable
Scenario: Member sees an error when uploading a file with no valid rows
  Given I am on the release securities page
  And the edit securities section is open
  When I drag and drop the "securities-no-rows.xlsx" file into the edit securities dropzone
  Then I should see a no securities field error

@jira-mem-1783 @data-unavailable
Scenario: Member uploads a securities release file that has an invalid Original Par
  Given I am on the release securities page
  And the edit securities section is open
  When I drag and drop the "securities_invalid_original_par.xlsx" file into the edit securities dropzone
  Then I should see an original par numericality field error

@jira-mem-1790 @jira-mem-1894 @data-unavailable
Scenario: Member uploads a securities release file that is missing Settlement Amount and the request has a settlement type of Free
  Given I am on the release securities page
  And the settlement type is set to Free
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And the edit securities section is open
  And I upload a securities release file with "no settlement amounts"
  When I click to submit the request
  Then I should see the title for the "pledge release" success page

@jira-mem-1790 @jira-mem-1894 @data-unavailable
Scenario: Member uploads a securities release file that is missing Settlement Amount and the request has a settlement type of Vs. Payment
  Given I am on the release securities page
  And the settlement type is set to Vs Payment
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And the edit securities section is open
  And I upload a securities release file with "no settlement amounts"
  When I click to submit the request
  Then I should see the "settlement amount required" error

@jira-mem-1792 @jira-mem-1894 @data-unavailable
Scenario: Member uploads a securities release file that has at least one security with an Original Par over the Federal Limit of 50,000,000
  Given I am on the release securities page
  And the edit securities section is open
  And I upload a securities release file with "an original par over the federal limit"
  And I select "Fed" as the release delivery instructions
  And I fill in the "clearing_agent_fed_wire_address_1" securities field with "23454343"
  And I fill in the "clearing_agent_fed_wire_address_2" securities field with "5683asdfa"
  And I fill in the "aba_number" securities field with "5683asdfa"
  When I click to submit the request
  Then I should see the "over federal limit" error

@jira-mem-1791 @jira-mem-1894 @data-unavailable
Scenario: Member uploads a securities release file that has Settlement Amounts and the request has a settlement type of Free
  Given I am on the release securities page
  And the settlement type is set to Free
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And the edit securities section is open
  And I upload a securities release file with "settlement amounts"
  When I click to submit the request
  Then I should see the "settlement amount present" error

@jira-mem-1791 @jira-mem-1894 @data-unavailable
Scenario: Member uploads a securities release file that has Settlement Amounts and the request has a settlement type of Vs. Payment
  Given I am on the release securities page
  And the settlement type is set to Vs Payment
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And the edit securities section is open
  And I upload a securities release file with "settlement amounts"
  When I click to submit the request
  Then I should see the title for the "pledge release" success page

@jira-mem-1654
Scenario: Member changes trade and settlement dates
  Given I am on the release securities page
  When I click the trade date datepicker
  Then I should see that weekends have been disabled
  And I click the datepicker cancel button
  Then I should be on the securities release page
  When I click the settlement date datepicker
  Then I should see that weekends have been disabled
  And I should see that all past dates have been disabled
  And I should not be able to see a calendar more than 3 months in the future
  And I click the datepicker cancel button
  Then I should be on the securities release page

@jira-mem-1786
Scenario Outline: Member selects a settlement date that occurs before the trade date
  Given I am on the <page> securities page
  And I choose the first available date for settlement date
  And I choose the last available date for trade date
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  When I click to submit the request
  Then I should see the "settlement date before trade date" error
Examples:
| page              |
| safekeep release  |
| pledge release    |

@jira-mem-1594 @jira-mem-1595
Scenario: Member sees success page after submitting releases for authorization
  Given I am on the release securities page
  When I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And I submit the securities release request for authorization
  Then I should see the title for the "pledge release" success page

@jira-mem-1600
Scenario: A signer uses a SecurID token to authenticate when authorizing
  Given I am logged in as a "quick-advance signer"
  And I am on the securities request page
  When I click to Authorize the first release
  Then I should be on the Securities Release page
  And the Authorize action is disabled
  When I enter "123" for my SecurID pin
  And I enter my SecurID token
  Then the Authorize action is disabled
  When I enter "12345" for my SecurID token
  And I enter my SecurID pin
  Then the Authorize action is disabled
  When I enter my SecurID pin and token
  Then the Authorize action is enabled
  When I enter "12ab" for my SecurID pin
  And I click to authorize the request
  Then I should see SecurID errors
  When I enter my SecurID pin
  And I enter "1234ab" for my SecurID token
  And I click to authorize the request
  Then I should see SecurID errors

@jira-mem-1601
Scenario: A signer authorizes a request while submitting it
  Given I am logged in as a "quick-advance signer"
  And I am on the release securities page
  When I fill in the "clearing_agent_participant_number" securities field with "23454343"
  When I authorize the request
  Then I should see the authorize request success page

@jira-mem-1785 @jira-mem-1894
Scenario Outline: A user cannot submit the form until all required fields have values
  When I am on the <page> securities page
  Then the Submit action is disabled
  When I fill in the "clearing_agent_participant_number" securities field with "23454343"
  Then the Submit action is enabled
Examples:
  | page             |
  | safekeep release |
  | pledge release   |

@jira-mem-1874 @data-unavailable
Scenario: Member uploads a securities intake file and sees the success message
  Given I am on the release securities page
  And the edit securities section is open
  And I upload a securities release file with "no settlement amounts"
  Then I should see the securities upload success message
  When the edit securities section is open
  And I drag and drop the "securities_invalid_original_par.xlsx" file into the edit securities dropzone
  Then I should not see the securities upload success message

@jira-mem-1894 @allow-rescue @local-only
Scenario Outline: A member submits a request for release and there is a general API error
  Given I am on the <page> securities page
  When I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And I submit the request and the API returns a 500
  Then I should see the "generic catchall" error
Examples:
| page              |
| safekeep release  |
| pledge release    |

@jira-mem-1897
Scenario Outline: Intranet users are not allowed to submit an intake request
  Given I log in as an "intranet user"
  When I am on the <page> securities page
  And I fill in the "clearing_agent_participant_number" securities field with "23454343"
  And I fill in the "dtc_credit_account_number" securities field with "5683asdfa"
  When I submit the securities request for authorization
  Then I should see the "intranet user" error
Examples:
| page              |
| safekeep release  |
| pledge release    |