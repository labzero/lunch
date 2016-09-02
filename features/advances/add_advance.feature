@jira-mem-1353 @flip-on-add-advance
Feature: Adding an Advance
  As a user
  I want to use the Add Advance flow
  In order to execute an advance

Background:
  Given I am logged in as a "quick-advance signer"

Scenario: Cannot navigate to the select rate page if I am not an advance-signer
  Given I am logged in as a "quick-advance non-signer"
  When I visit the dashboard
  And I hover on the advances link in the header
  Then I should not see the link for adding an advance

Scenario: Visit the select rate page if I am an advance-signer
  Given I visit the dashboard
  When I hover on the advances link in the header
  And I click on the add advance link in the header
  Then I should see the add advance rate table

Scenario: Cancelling an advance
  Given I am on the "Add Advance" advances page
  When I click the button to cancel my advance
  Then I should be on the Manage Advances page

Scenario: Add advance input field does not allow letters or symbols
  Given I am on the "Add Advance" advances page
  When I enter "asdf#*@&!asdf" into the add advance amount field
  Then the add advance amount field should be blank

Scenario: Add advance input field adds commas to input field
  Given I am on the "Add Advance" advances page
  When I enter "7894561235" into the add advance amount field
  Then the add advance amount field should show "7,894,561,235"

Scenario: Add advance tooltips and selecting a rate
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  When I hover on the cell with a term of "open" and a type of "agency" on the add advance page
  Then I should see the add advance table tooltip for the cell with a term of "open", a type of "agency" and a maturity date of "Open" on the add advance page
  When I click to toggle to the frc rates
  And I hover on the cell with a term of "2week" and a type of "whole" on the add advance page
  Then I should see the add advance table tooltip for the cell with a term of "2week" and a type of "whole" on the add advance page
  When I see the unselected state for the cell with a term of "2week" and a type of "whole" on the add advance page
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  Then I should see the selected state for the cell with a term of "2week" and a type of "whole" on the add advance page
  And the initiate advance button should be active on the add advance page

Scenario: Certain rates should be missing due to black out dates
  Given I am on the "Add Advance" advances page
  When I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  Then I should see a blacked out value for the "3week" term with a type of "aaa" on the add advance page

Scenario: Certain rates should be missing due to rate bands
  Given I am on the "Add Advance" advances page
  When I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  Then I should see a blacked out value for the "2year" term with a type of "aa" on the add advance page
  And I should see a blacked out value for the "3year" term with a type of "aa" on the add advance page

Scenario: 2 year rates should be missing due to override_end_date/override_end_time
  Given I am on the "Add Advance" advances page
  When I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  Then I should see a blacked out value for the "2year" term with a type of "whole" on the add advance page
  And I should see a blacked out value for the "2year" term with a type of "aa" on the add advance page
  And I should see a blacked out value for the "2year" term with a type of "aaa" on the add advance page
  And I should see a blacked out value for the "2year" term with a type of "agency" on the add advance page

Scenario: Preview rate from the Add Advance rate table
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should not see the add advance rate table
  And I should see a preview of the advance

Scenario: Check the interest payment frequencies for various term/type
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an advance interest payment frequency of "monthendorrepayment"
  When I click on the edit button for the add advance preview
  And I select the rate with a term of "3year" and a type of "agency" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an advance interest payment frequency of "semiannualandrepayment"
  When I click on the edit button for the add advance preview
  And I select the rate with a term of "3month" and a type of "aaa" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an advance interest payment frequency of "repayment"
  When I click on the edit button for the add advance preview
  And I click to toggle to the vrc rates
  And I select the rate with a term of "overnight" and a type of "aa" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an advance interest payment frequency of "maturity"

Scenario: Go back to rate table from preview
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "aaa" on the add advance page
  And I click on the initiate advance button on the add advance page
  Then I should not see the add advance rate table
  When I click on the edit button for the add advance preview
  Then I should see the add advance rate table
  And I should see the selected state for the cell with a term of "2week" and a type of "aaa" on the add advance page
  And I should not see a preview of the advance

Scenario: Users with insufficient funds for an advance get an error
  Given I am on the "Add Advance" advances page
  When I enter "100001" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an "insufficient financing availability" advance error with amount 100001 and type "whole"

Scenario: Users with insufficient collateral for an advance get an error
  Given I am on the "Add Advance" advances page
  When I enter "100002" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an "insufficient collateral" advance error with amount 100002 and type "whole"

Scenario: Users get an error if their requested advance would push FHLB over its total daily limit for web advances
  Given I am on the "Add Advance" advances page
  When I enter "100003" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an "advance unavailable" advance error with amount 100003 and type "whole"

Scenario: User sees collateral limit error if advance causes both collateral and capital stock limits error
  Given I am on the "Add Advance" advances page
  When I enter "100006" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an "insufficient collateral" advance error with amount 100006 and type "whole"

Scenario: Users gets an error if advance causes per-term cumulative amount to exceed limit
  Given I am on the "Add Advance" advances page
  When I enter "1000000000000" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should see an "advance unavailable" advance error with amount 1000000000000 and type "whole"

Scenario: Users are informed if they enter an invalid pin or token
  Given I am on the add advance preview screen
  When I enter "12ab" for my SecurID pin
  And I enter my SecurID token
  And I click on the add advance confirm button
  Then I should see SecurID errors on the preview page
  When I enter my SecurID pin
  And I enter "12ab34" for my SecurID token
  And I click on the add advance confirm button
  Then I should see SecurID errors on the preview page

Scenario: Users aren't required to enter a SecurID token a second time
  Given I am on the add advance preview screen
  When I enter my SecurID pin and token
  And I click on the add advance confirm button
  Then I should see confirmation number for the added advance
  When I click the get another advance button
  And I am on the add advance preview screen
  Then I shouldn't see the SecurID fields
  When I click on the add advance confirm button
  Then I should see confirmation number for the added advance

@data-unavailable
Scenario: The rate changes from the time the user sees the table to the time they see the preview
  Given I am on the add advance preview screen
  And the add advance rate has changed
  Then I should see a preview of the advance with a notification about the new rate
  And I should see an initiate advance button with a notification about the new rate

Scenario: User sees an unavailable message if advances are disabled for their bank
  Given I am logged in as a "user with disabled quick advances"
  When I am on the "Add Advance" advances page
  Then I should see an advances disabled message

Scenario: User who cancels an advance with a stock purchase doesn't see the stock purchase in the next advance
  Given I am on the add advance stock purchase screen
  And I select the continue with advance option
  When I click on the initiate advance button on the add advance page
  Then I should see the cumulative stock purchase on the add advance preview screen
  When I click on the edit button for the add advance preview
  And I preview a loan that doesn't require a capital stock purchase on the add advance page
  Then I should not see the cumulative stock purchase on the add advance preview screen

Scenario: User backs out of an advance requiring a capital stock purchase and then takes the same advance out
  Given I am on the add advance stock purchase screen
  And I select the continue with advance option
  When I click on the initiate advance button on the add advance page
  Then I should see the cumulative stock purchase on the add advance preview screen
  When I click on the edit button for the add advance preview
  And I enter "1000131" into the add advance amount field
  And I click to toggle to the frc rates
  And I select the rate with a term of "2week" and a type of "whole" on the add advance page
  And I click on the initiate advance button on the add advance page
  Then I should be on the add advance stock purchase screen

Scenario: User with signer privileges cannot navigate to the select rate page if their member bank requires dual signers
  Given I am logged in as a "dual-signer"
  When I visit the dashboard
  And I hover on the advances link in the header
  Then I should not see the link for adding an advance

Scenario: Confirm rate from advance preview dialog
  Given I am on the add advance preview screen
  And I enter my SecurID pin and token
  When I click on the add advance confirm button
  Then I should see confirmation number for the added advance
  And I should see the get another advance button

Scenario: User navigates to Manage Advances page from advance confirmation screen
  Given I successfully add an advance
  When I click the Manage Advances button
  Then I should be on the Manage Advances page

Scenario: User navigates to select rate page from advance confirmation screen
  Given I successfully add an advance
  When I click the get another advance button
  Then I should see the add advance rate table

@allow-rescue
Scenario: Users should not be able to get an advance if the product has been disabled by the desk after selecting from the rate table
  When I try to preview an added advance on a disabled product
  Then I should see an add advance error
  When I try to take out an added advance on a disabled product
  Then I should see an add advance error

Scenario: Users who wait too long to perform an advance are told that the rate has expired if the rate has changed
  Given I am on the add advance preview screen
  And I wait for 70 seconds
  When I confirm an added advance with a rate that changes
  Then I should see a "rate expired" advance error

Scenario: Users who wait too long to perform an advance can still execute the advance if the rate has not changed
  Given I am on the add advance preview screen
  And I wait for 70 seconds
  When I confirm an added advance with a rate that remains unchanged
  Then I should see confirmation number for the added advance

Scenario: User sees an unavailable message if online advances are disabled for their bank
  Given I am logged in as a "user with disabled quick advances"
  When I am on the "Add Advance" advances page
  Then I should see an add advances disabled message

Scenario: User sees a message if there are no rates being returned from the etransact service
  Given I visit the dashboard when etransact "has no terms"
  When I am on the "Add Advance" advances page
  Then I should see a no terms message

@jira-mem-1457
Scenario: User switches between VRC and FRC rates on the rate table
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  When I select the rate with a term of "open" and a type of "agency" on the add advance page
  Then I should see the selected state for the cell with a term of "open" and a type of "agency" on the add advance page
  And the initiate advance button should be active on the add advance page
  When I click to toggle to the frc rates
  Then I see the deactivated state for the initiate advance button on the add advance page
  And I should not see any rates selected
  When I select the rate with a term of "2week" and a type of "whole" on the add advance page
  Then I should see the selected state for the cell with a term of "2week" and a type of "whole" on the add advance page
  And the initiate advance button should be active on the add advance page
  When I click to toggle to the vrc rates
  Then I see the deactivated state for the initiate advance button on the add advance page
  And I should not see any rates selected

@jira-mem-1541
Scenario: User sees borrowing capacity summary module in the right column for add advances (and not elsewhere)
  Given I am on the "Add Advance" advances page
  Then I should see the borrowing capacity summary
  Given I am on the add advance preview screen
  Then I should not see the borrowing capacity summary
  Given I am on the add advance stock purchase screen
  Then I should not see the borrowing capacity summary

@jira-mem-1577
Scenario: User navigates to the select rate page from the Manage Advances page
  Given I am on the "Manage Advances" advances page
  When I click the Add Advance button
  Then I should see the add advance rate table

@jira-mem-1649 @flip-on-add-advance-custom-term
Scenario: User clicks on the FRC rates and sees Funding Date then selects today and begins the advance process
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  When I click to toggle to the frc rates
  Then I should see Funding Date information
  When I click on Edit Funding Date link
  Then I should see Set an Alternate Funding Date
  When I click on the Today radio button
  Then I should see the add advance rate table
  Then I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should not see the add advance rate table
  And I should see a preview of the advance

@jira-mem-1649 @flip-on-add-advance-custom-term
Scenario: User clicks on the FRC rates and sees Funding Date then selects next business day and begins the advance process
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  When I click to toggle to the frc rates
  Then I should see Funding Date information
  When I click on Edit Funding Date link
  Then I should see Set an Alternate Funding Date
  When I click on the Next Business Day radio button
  Then I should see the add advance rate table
  Then I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should not see the add advance rate table
  And I should see a preview of the advance

@jira-mem-1649 @flip-on-add-advance-custom-term
Scenario: User clicks on the FRC rates and sees Funding Date then selects skip business day and begins the advance process
  Given I am on the "Add Advance" advances page
  And I enter an amount into the add advance amount field
  When I click to toggle to the frc rates
  Then I should see Funding Date information
  When I click on Edit Funding Date link
  Then I should see Set an Alternate Funding Date
  When I click on the Skip Business Day radio button
  Then I should see the add advance rate table
  Then I select the rate with a term of "2week" and a type of "whole" on the add advance page
  When I click on the initiate advance button on the add advance page
  Then I should not see the add advance rate table
  And I should see a preview of the advance

