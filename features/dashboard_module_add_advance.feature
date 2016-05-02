@jira-mem-1461 @flip-on-add-advance
Feature: Add Advance Module on Dashboard
  As a user
  I want to interact with the Add Advance module on the dashboard
  So that I can view rate info and navigate to the Add Advance page

Background:
  Given I am logged in as a "quick-advance signer"

Scenario: Do not see dashboard add advance module if I am not an advance-signer
  Given I am logged in as a "quick-advance non-signer"
  When I visit the dashboard
  Then I should not see the add-advance module

Scenario: See dashboard add advance module if I am an advance-signer
  When I visit the dashboard
  Then I should see a dollar amount field in the add advance module
  And I should see an advance rate in the dashboard advance module

Scenario: Add advance input field does not allow letters or symbols
  When I enter "asdf#*@&!asdf" into the add advance amount field
  Then the add advance amount field should be blank

Scenario: Add advance input field adds commas to input field
  When I enter "7894561235" into the add advance amount field
  Then the add advance amount field should show "7,894,561,235"

Scenario: The View Recent Price Indications link is displayed when the desk is closed
  Given I visit the dashboard when etransact "is closed"
  When I click on the View Recent Price Indications link
  Then I am on the "Current Price Indications" report page

Scenario: A message is displayed when there is limited pricing
  Given I visit the dashboard when etransact "has limited pricing"
  And I click on the dashboard module limited pricing notice
  Then I should see the limited pricing information message

Scenario: User sees an unavailable message if online advances are disabled for their bank
  Given I am logged in as a "user with disabled quick advances"
  When I visit the dashboard
  Then I should see an add advances disabled message

Scenario: User sees a message if there are no rates being returned from the etransact service
  Given I visit the dashboard when etransact "has no terms"
  Then I should see a no terms message

Scenario: User with signer privileges does not see add advance module if their member bank requires dual signers
  Given I am logged in as a "dual-signer"
  When I visit the dashboard
  Then I should not see the add-advance module

Scenario: User visits the add advance page from the link in the dashboard module
  When I click on the view rate options link in the dashboard module
  Then I should see the add advance rate table
  And the add advance amount field should be blank
  And there should be no rate selected
