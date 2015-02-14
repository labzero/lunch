Feature: Visiting the Advances Detail Report Page
  As a user
  I want to use visit the advances detail report page for the FHLB Member Portal
  In order to view the details of my current and past advances

Background:
  Given I am logged in

@smoke
Scenario: Visit advances details page from header link
  Given I visit the dashboard
  When I select "Advances Detail" from the reports dropdown
  Then I should see report summary data
  And I should see a report table with multiple data rows

# NOTE: If this is changed to a smoke test and run against production data, "as_of_date" as returned by MAPI could be either today or yesterday depending on when the test is run
Scenario: Defaults to current advances details
  Given I visit the dashboard
  When I select "Advances Detail" from the reports dropdown
  Then I should see advances details for today

Scenario: Viewing historic advances details
  Given I am on the Advances Detail page
  When I click the datepicker field
  And I choose the custom date in the datepicker
  And I select the 14th of last month in the single datepicker calendar
  And I click the datepicker apply button
  Then I should see advances details for the 14th of last month

Scenario: Viewing the details of a given advance
  Given I am on the Advances Detail page
  When I click on the view cell for the first advance
  Then I should see the detailed view for the first advance
  When I click on the hide link for the first advance detail view
  Then I should not see the detailed view for the first advance

@smoke
Scenario: Member sorts the advances details report by certificate sequence
  Given I am on the Advances Detail page
  When I click the Trade Date column heading
  Then I should see the "Trade Date" column values in "ascending" order
  And I click the Trade Date column heading
  Then I should see the "Trade Date" column values in "descending" order