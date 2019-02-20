/* eslint-env mocha */
/* eslint-disable no-undef */
import * as helpers from '../../support/helpers';

const subdomain = Cypress.env('subdomain');

describe('other pages', () => {
  before(() => {
    helpers.login();
    helpers.deleteTeam();
    helpers.createTeam();
  });

  beforeEach(() => {
    helpers.login();
  });

  describe('hamburger menu', () => {
    it('expands to show menu contents', () => {
      cy.visit('');
      cy.get('#header button').click();
      cy.get('.Header-menuBackground').should('be.visible');
      cy.get('a.Menu-button').should('be.visible');
      cy.get('nav.Menu-root.Menu-open').should('be.visible').within(() => {
        cy.get('a').contains('Team').should('have.attr', 'href', '/team');
        cy.get('a').contains('Tags').should('have.attr', 'href', '/tags');
        cy.get('a').contains('My Teams').should('have.attr', 'href', '//local.lunch.pink:3000/teams');
        cy.get('a').contains('Account').should('have.attr', 'href', '//local.lunch.pink:3000/account');
        cy.get('a').contains('Log Out').should('have.attr', 'href', '//local.lunch.pink:3000/logout');
      });
    });
  });

  describe('Account page', () => {
    it('should have "Name," "Email," and "Change Password?" inputs and Submit button', () => {
      cy.visit('/account');
      cy.get('label').contains('Name').should('have.attr', 'for', 'account-name');
      cy.get('label').contains('Email');
      cy.contains('Change password?');
      cy.contains('Submit');
    });
  });

  describe('Tags page', () => {
    it('should display a list of tags when there are tags', () => {
      helpers.addRestaurant();
      helpers.addTag();
      cy.visit(`${subdomain}tags`);
      cy.contains('waterfront');
      helpers.deleteTag();
      helpers.deleteRestaurant();
    });

    it('should display blurb when no tags', () => {
      cy.visit(`${subdomain}tags`);
      cy.get('button.Tag-button').click();
      cy.get('.modal-footer .btn-primary').click();
      cy.contains('Once you add tags');
    });
  });

  describe('About page', () => {
    it('should have some content', () => {
      cy.visit('/about');
      cy.contains('About Lunch');
    });
  });

  describe('404 page', () => {
    it('should have some content', () => {
      cy.visit('/404', { failOnStatusCode: false });
      cy.contains('Page not found');
    });
  });
});
