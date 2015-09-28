@jira-mem-69
Feature: Visiting the Dividend Transaction Statement Page
  As a user
  I want to use visit the Dividend Transaction Statement page for the FHLB Member Portal
  In order to view my dividends for the last quarter

Background:
  Given I am logged in

@smoke @jira-mem-264
Scenario: Member sees Dividend Transaction Statement
  Given I visit the dashboard
  When I select "Dividend Transaction Statement" from the reports dropdown
  Then I should see report summary data
  And I should see 2 report tables with multiple data rows

@smoke @jira-mem-264
Scenario: Member sorts the Dividend Transaction Statement
  Given I am on the "Dividend Transaction Statement" report page
  And I should see the "Issue Date" column values in "ascending" order on the "Dividend Details" table
  When I click the "Issue Date" column heading
  Then I should see the "Issue Date" column values in "descending" order on the "Dividend Details" table
  When I click the "Certificate Sequence" column heading
  Then I should see the "Certificate Sequence" column values in "ascending" order on the "Dividend Details" table
  And I click the "Certificate Sequence" column heading
  Then I should see the "Certificate Sequence" column values in "descending" order on the "Dividend Details" table
  When I click the "Start Date" column heading
  Then I should see the "Start Date" column values in "ascending" order on the "Dividend Details" table
  And I click the "Start Date" column heading
  Then I should see the "Start Date" column values in "descending" order on the "Dividend Details" table
  When I click the "End Date" column heading
  Then I should see the "End Date" column values in "ascending" order on the "Dividend Details" table
  And I click the "End Date" column heading
  Then I should see the "End Date" column values in "descending" order on the "Dividend Details" table
  When I click the "Shares Outstanding" column heading
  Then I should see the "Shares Outstanding" column values in "ascending" order on the "Dividend Details" table
  And I click the "Shares Outstanding" column heading
  Then I should see the "Shares Outstanding" column values in "descending" order on the "Dividend Details" table
  When I click the "Days Outstanding" column heading
  Then I should see the "Days Outstanding" column values in "ascending" order on the "Dividend Details" table
  And I click the "Days Outstanding" column heading
  Then I should see the "Days Outstanding" column values in "descending" order on the "Dividend Details" table
  When I click the "Average Shares Outstanding" column heading
  Then I should see the "Average Shares Outstanding" column values in "ascending" order on the "Dividend Details" table
  And I click the "Average Shares Outstanding" column heading
  Then I should see the "Average Shares Outstanding" column values in "descending" order on the "Dividend Details" table
  When I click the "Dividend" column heading
  Then I should see the "Dividend" column values in "ascending" order on the "Dividend Details" table
  And I click the "Dividend" column heading
  Then I should see the "Dividend" column values in "descending" order on the "Dividend Details" table

@smoke @jira-mem-787
Scenario: Member selects a previous Dividend Transaction Statement
  Given I am on the "Dividend Transaction Statement" report page
  When I click on the dividend transaction dropdown selector
  And I click on the last option in the dividend transaction dropdown selector
  Then I should see a dividend summary for the last option in the dividend transaction dropdown selector

@data-unavailable @jira-mem-264
Scenario: No data is available to show in the Dividend Transaction Statement Statement
  Given I am on the "Dividend Transaction Statement" report page
  When the "Dividend Summary" table has no data
  Then I should see a "Dividend Summary" report table with all data missing
  When the "Dividend Details" table has no data
  Then I should see the "Dividend Details" report table with Data Unavailable messaging

@data-unavailable @jira-mem-264
Scenario: The Dividend Transaction Statement has been disabled
  Given I am on the "Dividend Transaction Statement" report page
  When the "Dividend Transaction Statement" report has been disabled
  Then I should see a "Dividend Summary" report table with all data missing
  Then I should see the "Dividend Details" report table with Data Unavailable messaging