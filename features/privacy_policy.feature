Feature: Viewer visits the Privacy Policy Page
  In order to read the page
  As a viewer
  I want to see the Privacy Policy page

@jira-mem-674
Scenario: View privacy policy page
  Given I am logged out
  When I visit the privacy policy page
  Then I see the privacy policy
