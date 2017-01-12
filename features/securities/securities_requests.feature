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
  When I click on the securities link in the header
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
  | security_type     | page                | legal_copy_visibility |
  | pledge release    | Securities Release  | see                   |
  | safekept release  | Securities Release  | not see               |
  | pledge intake     | Pledge Securities   | see                   |
  | safekept intake   | Safekeep Securities | not see               |
  | pledge transfer   | Transfer Securities | see                   |
  | safekept transfer | Transfer Securities | see                   |

@jira-mem-1870
Scenario Outline: Signers only see authorize links for matching securities kinds
  Given I am logged in as a "<user>"
  When I am on the securities request page
  When I click to Authorize the first <security_type>
  Then I should be on the <page> page
Examples:
  | user              | security_type     | page                |
  | securities signer | safekept intake   | Safekeep Securities |
  | collateral signer | pledge intake     | Pledge Securities   |
  | collateral signer | pledge transfer   | Transfer Securities |

@jira-mem-1870
Scenario Outline: Signers cannot authorize links for securities that don't match their authorizations
  Given I am logged in as a "<user>"
  When I am on the securities request page
  Then I should see the active state for the Authorize action for <authorized_request_type>
  Then I should see the disabled state for the Authorize action for <unauthorized_request_type>
Examples:
  | user              | authorized_request_type        | unauthorized_request_type |
  | securities signer | safekept release               | pledge release            |
  | collateral signer | pledge release                 | safekept release          |

@jira-mem-1870
Scenario: Collateral signers can authorize pledge transfers and safekept transfers
  Given I am logged in as a "collateral signer"
   When I am on the securities request page
   Then I should see the active state for the Authorize action for pledge transfer
   And I should see the active state for the Authorize action for safekept transfer

@jira-mem-1599 @jira-mem-1667
Scenario Outline: A signer authorizes a previously submitted request
  Given I am logged in as a "<user>"
  And I am on the securities request page
  When I click to Authorize the first <request_type>
  Then I should be on the <page> page
  When I choose the first available date for trade date
  And I choose the last available date for settlement date
  And I select "Fed" as the release delivery instructions
  And I fill in the "clearing_agent_fed_wire_address_1" securities field with "23454343"
  And I fill in the "clearing_agent_fed_wire_address_2" securities field with "5683asdfa"
  And I fill in the "aba_number" securities field with "123456789"
  And I authorize the request
  Then I should see the authorize request success page
Examples:
  | user                 | request_type    | page                |
  | collateral signer    | pledge intake   | Pledge Securities   |
  | securities signer    | safekept intake | Safekeep Securities |

@jira-mem-1738
Scenario Outline: A signer authorizes a previously submitted request
  Given I am logged in as a "quick-advance signer"
  And I am on the securities request page
  When I click to Authorize the first <type>
  Then I should be on the Transfer Securities page
  And I authorize the request
  Then I should see the authorize request success page
Examples:
| type             |
| pledge transfer  |
| safekept transfer |

@jira-mem-1685
Scenario Outline: Download a PDF of an authorized security request
  Given I am on the securities request page
  When I request a PDF of an authorized <type> securities request
  Then I should begin downloading a file
Examples:
| type              |
| pledge release    |
| safekept release  |
| pledge intake     |
| safekept intake   |
| pledge transfer   |
| safekept transfer |

@jira-mem-1741 @jira-mem-2126
Scenario Outline: Signer starts to delete a previously submitted request
  Given I am logged in as a "<user>"
  And I am on the securities request page
  When I click to Authorize the first <request_type> request
  Then I should be on the <page> page
  When I click the button to delete the request
  Then I should see the delete request flyout dialogue
Examples:
  | request_type      | page                | user              |
  | pledge release    | Securities Release  | collateral signer |
  | safekept release  | Securities Release  | securities signer |
  | pledge intake     | Pledge Securities   | collateral signer |
  | safekept intake   | Safekeep Securities | securities signer |
  | pledge transfer   | Transfer Securities | collateral signer |
  | safekept transfer | Transfer Securities | collateral signer |

@jira-mem-1741 @jira-mem-2126 @data-unavailable
Scenario Outline: Signer deletes a previously submitted request
  Given I am logged in as a "<user>"
  And I am on the securities request page
  When I click to Authorize the first <request_type> request
  Then I should be on the <page> page
  When I click the button to delete the request
  And I confirm that I want to delete the request
  Then I should be on the Securities Requests page
  And I should not see the request ID that I deleted
Examples:
  | request_type      | page                | user              |
  | pledge release    | Securities Release  | collateral signer |
  | safekept release  | Securities Release  | securities signer |
  | pledge intake     | Pledge Securities   | collateral signer |
  | safekept intake   | Safekeep Securities | securities signer |
  | pledge transfer   | Transfer Securities | collateral signer |
  | safekept transfer | Transfer Securities | collateral signer |
