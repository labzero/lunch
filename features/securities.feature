Feature: Using the Securities tab
  As a user
  I want to use the Securities tab
  To visit the old FHLB web-site

Background:
  Given I am logged in

@smoke
Scenario: Visit Securities and cancel it
  When I click on the securities link in the header
  Then I should see the securities flyout
  When I cancel the Securities flyout
  Then I should not see the securities flyout

@smoke
Scenario: Visit Securities and continue to the external site
  When I click on the securities link in the header
  Then I should see the securities flyout
  When I continue the Securities flyout
  Then I should not see the securities flyout