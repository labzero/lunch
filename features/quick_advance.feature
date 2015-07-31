Feature: Making a Quick Advance
  As a user
  I want to use visit the dashboard for the FHLB Member Portal
  In order to execute a quick advance

Background:
  Given I am logged in as a "quick-advance signer"

@jira-mem-494
Scenario: Do not see dashboard quick advance module if I am not an advance-signer
  Given I am logged in as a "quick-advance non-signer"
  When I visit the dashboard
  Then I should not see the quick-advance module

@jira-mem-494
Scenario: See dashboard quick advance module if I am an advance-signer
  When I visit the dashboard
  Then I should see a dollar amount field
  And I should see an advance rate.

Scenario: Quick Advance flyout opens
  When I visit the dashboard
  And I enter "56503000" into the ".dashboard-module-advances input" input field
  Then I should see a flyout
  And I should see "56503000" in the quick advance flyout input field

Scenario: Quick Advance flyout closes
  When I visit the dashboard
  And I open the quick advance flyout
  And I click on the flyout close button
  Then I should not see a flyout

@jira-mem-229 @jira-mem-506
Scenario: Quick Advance flyout table
  When I visit the dashboard
  And I open the quick advance flyout
  Then I should see the quick advance table
  And I should see a rate for the "overnight" term with a type of "whole"

Scenario: Quick Advance flyout tooltip
  Given I visit the dashboard
  And I open the quick advance flyout
  When I hover on the cell with a term of "overnight" and a type of "whole"
  Then I should see the quick advance table tooltip for the cell with a term of "overnight" and a type of "whole"

Scenario: Select rate from Quick Advance flyout table
  Given I visit the dashboard
  And I open the quick advance flyout
  And I see the unselected state for the cell with a term of "open" and a type of "whole"
  When I select the rate with a term of "open" and a type of "whole"
  Then I should see the selected state for the cell with a term of "open" and a type of "whole"
  And the initiate advance button should be active

Scenario: Preview rate from Quick Advance flyout table
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "overnight" and a type of "whole"
  When I click on the initiate advance button
  Then I should not see the quick advance table
  And I should see a preview of the quick advance

Scenario: Go back to rate table from preview in Quick Advance flyout
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "1week" and a type of "aaa"
  And I click on the initiate advance button
  Then I should not see the quick advance table
  When I click on the back button for the quick advance preview
  Then I should see the quick advance table
  And I should see the selected state for the cell with a term of "1week" and a type of "aaa"
  And I should not see a preview of the quick advance

@data-unavailable @jira-mem-560
Scenario: Confirm rate from Quick Advance preview dialog
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "overnight" and a type of "whole"
  And I click on the initiate advance button
  And I should not see the quick advance table
  And I should see a preview of the quick advance
  And I enter my SecurID pin and token
  When I click on the quick advance confirm button
  Then I should see the quick advance interstitial
  And I should see confirmation number for the advance
  And I should not see the quick advance preview message
  And I should see the quick advance confirmation close button

@jira-mem-878
Scenario: Users must with insufficient funds for Quick Advance get an error
  Given I visit the dashboard
  And I open the quick advance flyout and enter 100001
  And I select the rate with a term of "overnight" and a type of "whole"
  When I click on the initiate advance button
  Then I should see a insufficient financing availability error with amount 100001

@data-unavailable @jira-mem-560
Scenario: Close flyout after finishing quick advance
  Given I visit the dashboard
  And I successfully execute a quick advance
  And I should see a flyout
  When I click on the quick advance confirmation close button
  Then I should not see a flyout

@data-unavailable @jira-mem-560
Scenario: Users are required to enter a SecurID token to take out an advance
  Given I visit the dashboard
  And I am on the quick advance preview screen
  When I click on the quick advance confirm button
  Then I should see SecurID errors
  When I enter my SecurID pin and token
  And I click on the quick advance confirm button
  Then I should see confirmation number for the advance

@jira-mem-560
Scenario: Users are informed if they enter an invalid pin or token
  Given I visit the dashboard
  And I am on the quick advance preview screen
  When I enter "12ab" for my SecurID pin
  And I enter my SecurID token
  And I click on the quick advance confirm button
  Then I should see SecurID errors
  When I enter my SecurID pin
  And I enter "12ab34" for my SecurID token
  And I click on the quick advance confirm button
  Then I should see SecurID errors

@data-unavailable @jira-mem-560
Scenario: Users aren't required to enter a SecurID token a second time
  Given I visit the dashboard
  And I am on the quick advance preview screen
  When I click on the quick advance confirm button
  When I enter my SecurID pin and token
  And I click on the quick advance confirm button
  Then I should see confirmation number for the advance
  When I click on the quick advance confirmation close button
  And I am on the quick advance preview screen
  Then I shouldn't see the SecurID fields
  When I click on the quick advance confirm button
  Then I should see confirmation number for the advance