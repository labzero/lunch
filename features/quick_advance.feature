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

@jira-mem-924
Scenario: Quick Advance flyout opens with commas in the amount field
  When I visit the dashboard
  And I enter "56503000" into the ".dashboard-module-advances input" input field
  Then I should see a flyout
  And I should see "56,503,000" in the quick advance flyout input field

@jira-mem-1175
Scenario: Quick Advance flyout opens when user clicks the Overnight VRC label or rate
  When I visit the dashboard
  And I click on the VRC Overnight label
  Then I should see a flyout
  When I close the quick advance flyout
  And I click on the VRC Overnight rate
  Then I should see a flyout

Scenario: Quick Advance flyout closes
  When I visit the dashboard
  And I open the quick advance flyout
  And I click on the flyout close button
  Then I should not see a flyout

@jira-mem-924
Scenario: Quick Advance flyout does not open when letters are entered
  When I visit the dashboard
  And I enter "asdfsdf" into the ".dashboard-module-advances input" input field
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
  When I hover on the cell with a term of "2week" and a type of "whole"
  Then I should see the quick advance table tooltip for the cell with a term of "2week" and a type of "whole"

@jira-mem-979
Scenario: Quick Advance flyout tooltip for Open advances
  Given I visit the dashboard
  And I open the quick advance flyout
  When I hover on the cell with a term of "open" and a type of "agency"
  Then I should see the quick advance table tooltip for the cell with a term of "open", a type of "agency" and a maturity date of "Open"

Scenario: Select rate from Quick Advance flyout table
  Given I visit the dashboard
  And I open the quick advance flyout
  And I see the unselected state for the cell with a term of "2week" and a type of "whole"
  When I select the rate with a term of "2week" and a type of "whole"
  Then I should see the selected state for the cell with a term of "2week" and a type of "whole"
  And the initiate advance button should be active

@jira-mem-737
Scenario: Certain rates should be missing due to black out dates
  Given I visit the dashboard
  And I open the quick advance flyout
  Then I should see a blacked out value for the "3week" term with a type of "aaa"

@jira-mem-733
Scenario: Certain rates should be missing due to rate bands
  Given I visit the dashboard
  And I open the quick advance flyout
  Then I should see a blacked out value for the "2year" term with a type of "aa"
  And I should see a blacked out value for the "3year" term with a type of "aa"

@jira-mem-1056
Scenario: 2 year rates should be missing due to override_end_date/override_end_time
  Given I visit the dashboard
  And I open the quick advance flyout
  Then I should see a blacked out value for the "2year" term with a type of "whole"
  And I should see a blacked out value for the "2year" term with a type of "aa"
  And I should see a blacked out value for the "2year" term with a type of "aaa"
  And I should see a blacked out value for the "2year" term with a type of "agency"

Scenario: Preview rate from Quick Advance flyout table
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should not see the quick advance table
  And I should see a preview of the quick advance

@jira-mem-1179
Scenario: Check the interest payment frequencies for various term/type
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an interest payment frequency of "monthendorrepayment"
  When I click on the back button for the quick advance preview
  And I select the rate with a term of "3year" and a type of "agency"
  When I click on the initiate advance button
  Then I should see an interest payment frequency of "semiannualandrepayment"
  When I click on the back button for the quick advance preview
  And I select the rate with a term of "3month" and a type of "aaa"
  When I click on the initiate advance button
  Then I should see an interest payment frequency of "repayment"
  When I click on the back button for the quick advance preview
  And I select the rate with a term of "overnight" and a type of "aa"
  When I click on the initiate advance button
  Then I should see an interest payment frequency of "maturity"

Scenario: Go back to rate table from preview in Quick Advance flyout
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "2week" and a type of "aaa"
  And I click on the initiate advance button
  Then I should not see the quick advance table
  When I click on the back button for the quick advance preview
  Then I should see the quick advance table
  And I should see the selected state for the cell with a term of "2week" and a type of "aaa"
  And I should not see a preview of the quick advance

@jira-mem-560
Scenario: Confirm rate from Quick Advance preview dialog
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "2week" and a type of "whole"
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
Scenario: Users with insufficient funds for Quick Advance get an error
  Given I visit the dashboard
  And I open the quick advance flyout and enter 100001
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an "insufficient financing availability" error with amount 100001 and type "whole"

@jira-mem-875
Scenario: Users with insufficient collateral for Quick Advance get an error
  Given I visit the dashboard
  And I open the quick advance flyout and enter 100002
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an "insufficient collateral" error with amount 100002 and type "whole"

@jira-mem-560
Scenario: Close flyout after finishing quick advance
  Given I visit the dashboard
  And I successfully execute a quick advance
  And I should see a flyout
  When I click on the quick advance confirmation close button
  Then I should not see a flyout

@jira-mem-560
Scenario: Users are required to enter a SecurID token to take out an advance
  Given I visit the dashboard
  And I am on the quick advance preview screen
  When I click on the quick advance confirm button
  Then I should see a preview of the quick advance
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

@jira-mem-560
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


@data-unavailable @jira-mem-872 @jira-mem-1028
Scenario: The rate changes from the time the user sees the table to the time they see the preview
  Given I visit the dashboard
  And I open the quick advance flyout
  And I select the rate with a term of "overnight" and a type of "whole"
  When I click on the initiate advance button
  And the quick advance rate has changed
  Then I should see a preview of the quick advance with a notification about the new rate
  And I should see an initiate advance button with a notification about the new rate

@data-unavailable @jira-mem-577
Scenario: The View Recent Price Indications link is displayed when the desk is closed
  Given I visit the dashboard
  And the desk has closed
  When I click on the View Recent Price Indications link
  Then I am on the "Current Price Indications" report page

@data-unavailable @jira-mem-569
Scenario: A message is displayed when there is limited pricing
  Given I visit the dashboard
  And there is limited pricing today
  When I click on the link to view limited pricing information
  Then I should see the limited pricing information message

@jira-mem-735
Scenario: Users get an error if their requested advance would push FHLB over its total daily limit for web advances
  Given I visit the dashboard
  And I open the quick advance flyout and enter 100003
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an "advance unavailable" error with amount 100003 and type "whole"

@jira-mem-117 @jira-mem-1114
Scenario: Users who wait too long to perform an advance are told that the rate has expired if the rate has changed
  Given I visit the dashboard
  And I am on the quick advance preview screen
  And I wait for 70 seconds
  When I confirm an advance with a rate that changes
  Then I should see a "rate expired" error

@jira-mem-117 @jira-mem-1114
Scenario: Users who wait too long to perform an advance can still execute the advance if the rate has not changed
  Given I visit the dashboard
  And I am on the quick advance preview screen
  And I wait for 70 seconds
  When I confirm an advance with a rate that remains unchanged
  Then I should see confirmation number for the advance

@jira-mem-883
Scenario: Users gets an error if advance causes per-term cumulative amount to exceed limit
  Given I visit the dashboard
  And I open the quick advance flyout and enter 1000000000000
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an "advance unavailable" error with amount 1000000000000 and type "whole"

@jira-mem-926
Scenario: User sees an unavailable message if quick advances are disabled for their bank
  Given I am logged in as a "user with disabled quick advances"
  When I visit the dashboard
  Then I should see a quick advances disabled message

@jira-mem-1197
Scenario: User who cancels an advance with a stock purchase doesn't see the stock purchase in the next advance
  Given I visit the dashboard
  And I am on the quick advance stock purchase screen
  And I select the continue with advance option
  When I click on the continue with request button
  Then I should see the cumulative stock purchase on the preview screen
  When I go back to the quick advance rate table
  And I preview a loan that doesn't require a capital stock purchase
  Then I should not see the cumulative stock purchase on the preview screen

Scenario: User who has a failed advance doesn't see a double render of the cap stock flow
  Given I visit the dashboard
  And I am on the quick advance stock purchase screen for an advance with a collateral error
  When I select the continue with advance option
  And I click on the continue with request button
  Then I see a collateral limit error
  When I go back to the quick advance rate table
  And I am on the quick advance stock purchase screen
  And I select the continue with advance option
  And I click on the continue with request button
  Then I should see a preview of the quick advance
  When I go back to the capital stock purchase screen
  Then I should see only one quick advance stock purchase screen

@jira-mem-1156
Scenario: User navigates to Manage Advances page from quick advance confirmation screen
  Given I visit the dashboard
  And I successfully execute a quick advance
  When I click the Manage Advances button
  Then I should be on the Manage Advances page

@jira-mem-1178
Scenario: User backs out of an advance requiring a capital stock purchase and then takes the same advance out
  Given I visit the dashboard
  And I am on the quick advance stock purchase screen
  And I select the continue with advance option
  When I click on the continue with request button
  Then I should see a preview of the quick advance
  When I go back to the quick advance rate table
  And I open the quick advance flyout and enter 1000131
  And I select the rate with a term of "2week" and a type of "whole"
  And I click on the initiate advance button
  Then I should be on the quick advance stock purchase screen

@jira-mem-1168
Scenario: User sees collateral limit error if advance causes both collateral and capital stock limits error
  Given I visit the dashboard
  And I open the quick advance flyout and enter 100006
  And I select the rate with a term of "2week" and a type of "whole"
  When I click on the initiate advance button
  Then I should see an "insufficient collateral" error with amount 100006 and type "whole"

@jira-mem-983 @allow-rescue
Scenario: Users should not be able to get an advance if the product has been disabled by the desk after selection on the rate table
  Given I visit the dashboard
  When I try and preview an advance on a disabled product
  Then I should see a quick advance error
  When I close the quick advance flyout
  And I try and take out an advance on a disabled product
  Then I should see a quick advance error
