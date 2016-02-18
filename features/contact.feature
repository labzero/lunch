Feature: Viewer visits the Contact Page
  In order to get the contact information for FHLB - San Francisco

Scenario: View the contact page
  Given I am logged in
  When I visit the contact page
  Then I see the contact information for FHLB
