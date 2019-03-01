/* eslint-disable no-undef */

describe('landing page', () => {
  before(() => {
    cy.visit('/');
  });

  it('contains hero text and has login link', () => {
    cy.contains('Figure it out');
    cy.get('#header .btn').contains('Log in').should('have.attr', 'href', '/login');
  });
});
