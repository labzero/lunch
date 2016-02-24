Feature: Forms Page
  As a user
  I want to see Bank provided forms
  In order to easily submit required documentation

Background:
  Given I am logged in

@smoke
Scenario: Member navigates to the agreements topic on the forms page via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the agreements link in the header
  Then I should see the forms page focused on the agreements topic

Scenario: Member navigates to the authorizations topic on the forms page via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the authorizations link in the header
  Then I should see the forms page focused on the authorizations topic

Scenario: Member navigates to the credit topic on the forms page via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the credit link in the header
  Then I should see the forms page focused on the credit topic

Scenario: Member navigates to the collateral topic on the forms page via the resources dropdown
  Given I hover on the resources link in the header
  When I click on the collateral link in the header
  Then I should see the forms page focused on the collateral topic

Scenario: Member sees forms on the forms page
  Given I am on the forms page
  Then I should see at least one form to download

@smoke
Scenario: Member uses the forms ToC to jump between topics
  Given I am on the forms page
  When I click on the agreements link in the ToC
  Then I should see the forms page focused on the agreements topic
  When I click on the authorizations link in the ToC
  Then I should see the forms page focused on the authorizations topic
  When I click on the credit link in the ToC
  Then I should see the forms page focused on the credit topic
  When I click on the collateral link in the ToC
  Then I should see the forms page focused on the collateral topic
