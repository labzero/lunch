/* eslint-env mocha */
/* eslint-disable no-undef */
import * as helpers from '../../support/helpers';

describe('teams page (no teams)', () => {
  before(() => {
    helpers.login();
    helpers.deleteTeam();
  });

  beforeEach(() => {
    helpers.login();
  });

  it('shows that there are no teams', () => {
    cy.visit('/teams');
    cy.contains('You’re not currently a part of any teams!');
  });

  it('takes user to create team page', () => {
    cy.visit('/teams');
    cy.get('.btn-default').click();
    cy.contains('Create a new team');
  });

  describe('new team page', () => {
    it('has a new team form', () => {
      cy.visit('/new-team');
      cy.contains('Create a new team');
      cy.get('form');
    });

    it('creates a new team successfully', () => {
      cy.visit('/new-team');
      cy.get('#newTeam-name').type('test');
      cy.get('#newTeam-slug').type('integration-test');
      cy.get('#newTeam-address').type('77 Battery Street, San Francisco, CA, USA');
      cy.get('button[type="submit"]').click();

      cy.contains('Visit one of your teams');
      cy.get('a.list-group-item').contains('test');
    });

    it('deletes a team successfully', () => {
      helpers.deleteTeam();
      cy.contains('You’re not currently a part of any teams!');
      cy.contains('Create a new team');
    });
  });
});
