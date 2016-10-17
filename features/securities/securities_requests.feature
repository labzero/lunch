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
  Then I should see a disabled state for the Authorize action

@jira-mem-1597 @jira-mem-1740 @jira-mem-1937
Scenario Outline: Securities signer navigates to view a request from the Securities Requests page
  Given I am logged in as a "quick-advance signer"
  When I am on the securities request page
  Then I should see the active state for the Authorize action
  When I click to Authorize the first <security_type>
  Then I should be on the <page> page
  And I should <legal_copy_visibility> the securities legal copy
Examples:
  | security_type | page                | legal_copy_visibility |
  | release       | Securities Release  | not see               |
  | pledge        | Pledge Securities   | see                   |
  | safekeep      | Safekeep Securities | not see               |
  | transfer      | Transfer Securities | see                   |

@jira-mem-1870
Scenario Outline: Signers only see authorize links for matching securities kinds
  Given I am logged in as a "<user>"
  When I am on the securities request page
  When I click to Authorize the first <security_type>
  Then I should be on the <page> page
Examples:
  | user              | security_type   | page                |
  | securities signer | safekeep        | Safekeep Securities |
  | collateral signer | pledge          | Pledge Securities   |
  | collateral signer | transfer        | Transfer Securities |

@jira-mem-1870
Scenario Outline: Signers cannot authorize links for securities that don't match their authorizations
  Given I am logged in as a "<user>"
  When I am on the securities request page
  Then I should see the active state for the Authorize action for <authorized_request_type>
  Then I should see the disabled state for the Authorize action for <unauthorized_request_type>
Examples:
  | user              | authorized_request_type | unauthorized_request_type |
  | securities signer | safekeep                | pledge                    |
  | collateral signer | pledge                  | safekeep                  |
  | collateral signer | transfer                | safekeep                  |

@jira-mem-1599 @jira-mem-1667
Scenario Outline: A signer authorizes a previously submitted request
  Given I am logged in as a "<user>"
  And I am on the securities request page
  When I click to Authorize the first <request_type>
  Then I should be on the <page> page
  When I choose the first available date for trade date
  And I choose the first available date for settlement date
  And I authorize the request
  Then I should see the authorize request success page
Examples:
  | user                 | request_type | page                |
  | collateral signer    | pledge       | Pledge Securities   |
  | securities signer    | safekeep     | Safekeep Securities |

@jira-mem-1738
Scenario: A signer authorizes a previously submitted request
  Given I am logged in as a "quick-advance signer"
  And I am on the securities request page
  When I click to Authorize the first transfer
  Then I should be on the Transfer Securities page
  And I authorize the request
  Then I should see the authorize request success page

@jira-mem-1685
Scenario Outline: Download a PDF of an authorized security request
  Given I am on the securities request page
  When I request a PDF of an authorized <type> securities request
  Then I should begin downloading a file
Examples:
| type     |
| pledge   |
| release  |
| safekeep |
| transfer |

@jira-mem-1741 @data-unavailable
Scenario Outline: Signer deletes a previously submitted request
  Given I am logged in as a "quick-advance signer"
  And I am on the securities request page
  When I click to Authorize the first <request_type> request
  Then I should be on the <page> page
  When I click the button to delete the request
  And I confirm that I want to delete the request
  Then I should be on the Securities Requests page
  And I should not see the request ID that I deleted
Examples:
  | request_type | page                |
  | release      | Securities Release  |
  | pledge       | Pledge Securities   |
  | safekeep     | Safekeep Securities |
  | transfer     | Transfer Securities |