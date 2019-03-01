/* eslint-env mocha */
/* eslint-disable no-undef */
import * as helpers from '../../support/helpers';

const subdomain = Cypress.env('subdomain');

describe('team page (within team)', () => {
  before(() => {
    helpers.login();
    helpers.deleteTeam();
    helpers.createTeam();
  });

  beforeEach(() => {
    helpers.login();
    cy.visit(`${subdomain}team`);
  });

  describe('team page', () => {
    it('should have Users, Team, and Messy Business tabs (for team owner)', () => {
      cy.contains('Users');
      cy.contains('Team');
      cy.contains('Messy Business');
      cy.get('#team-tabs-tab-1');
      cy.get('#team-tabs-tab-2');
      cy.get('#team-tabs-tab-3');
    });

    describe('under Users tab', () => {
      it('should have User List and Add User form', () => {
        cy.contains('User List');
        cy.contains('Add User');
      });
    });

    describe('under Team tab', () => {
      it('should have Name input, Address section, Sort duration, and Save Changes button', () => {
        cy.get('#team-tabs-tab-2').click();
        cy.contains('Name');
        cy.contains('Address');
        cy.contains('Sort duration');
        cy.contains('Save Changes');
      });
    });

    describe('under Messy Business tab', () => {
      it('should have Change team URL button and Delete team button', () => {
        cy.get('#team-tabs-tab-3').click();
        cy.get('.btn-danger').should('be.visible');
        cy.contains('Change team URL');
        cy.contains('Delete team');
      });
    });
  });
});
