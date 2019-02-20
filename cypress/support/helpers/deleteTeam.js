/* eslint-disable no-undef */
export default () => {
  cy.visit('/');

  cy.get('body').then(($body) => {
    if ($body.text().includes('You’re not currently a part of any teams!')) {
      // nothing to do, team doesn't exist
    } else {
      cy.visit(`${Cypress.env('subdomain')}team`);
      cy.get('div.Team-root');
      cy.get('#team-tabs-tab-3').click();
      cy.get('.btn-danger').contains('Delete team').should('be.visible').click();
      cy.get('#deleteTeamModal-confirmSlug').type('integration-test');
      cy.get('.modal-footer button[type="submit"]').contains('Delete').then(($btn) => {
        cy.wrap($btn).should('not.have.attr', 'disabled');
        cy.wrap($btn).click();
      });
      cy.wait(500); // prevents Cypress from firing off a request to create a team before the old one is deleted
    }
  });
};
