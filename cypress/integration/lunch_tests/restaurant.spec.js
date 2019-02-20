/* eslint-env mocha */
/* eslint-disable no-undef */
import * as helpers from '../../support/helpers';

const subdomain = Cypress.env('subdomain');

describe('Adding a restaurant and tag', () => {
  before(() => {
    helpers.login();
    helpers.deleteTeam();
    helpers.createTeam();
    cy.visit('/');
  });

  beforeEach(() => {
    helpers.login();
  });

  describe('landing page (logged in)', () => {
    it('loads the map and geosuggest input field', () => {
      cy.get('.RestaurantMap-root');
      cy.get('.RestaurantMap-mapSettingsContainer');
      cy.get('.geosuggest__input').should('have.prop', 'placeholder', 'Add places');
    });

    describe('with no restaurants', () => {
      it('shows the Welcome box', () => {
        cy.contains('Welcome to Lunch!');
      });
    });

    describe('Adding a restaurant', () => {
      it('makes suggestions and then displays the new restaurant in the restaurant list', () => {
        cy.visit(subdomain);
        cy.get('.geosuggest__input').type('ferry building');
        cy.get('li.RestaurantAddForm-suggestItemActive').click();
        cy.contains('filter by name');
        cy.get('.Restaurant-root');
        helpers.deleteRestaurant();
      });

      it('show the restaurant list item with contents', () => {
        helpers.addRestaurant();
        cy.get('ul.RestaurantList-root').as('restaurant');
        cy.get('@restaurant').find('div.Restaurant-data');
        cy.get('@restaurant').find('div.Restaurant-voteContainer');
        cy.get('@restaurant').find('div.Restaurant-footer');
        helpers.deleteRestaurant();
      });

      it('deletes a restaurant successfully', () => {
        helpers.addRestaurant();
        helpers.deleteRestaurant();
        cy.contains('Welcome to Lunch!');
      });
    });

    describe('Adding a tag', () => {
      it('shows the three filter buttons after adding a tag', () => {
        helpers.addRestaurant();
        helpers.addTag();
        cy.contains('filter by tag');
        cy.contains('exclude tags');
        cy.contains('waterfront');
        helpers.deleteTag();
      });

      it('deletes a tag successfully', () => {
        helpers.addTag();
        helpers.deleteTag();
        cy.get('waterfront').should('not.exist');
      });
    });
  });
});
