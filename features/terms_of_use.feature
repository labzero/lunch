Feature: Viewer visits the Terms of Use Page
  In order to read the page
  As a viewer
  I want to see the Terms of Use page

@jira-mem-674
Scenario: View terms of use page
  Given I am logged in
  When I visit the terms of use page
  Then I see the terms of use
