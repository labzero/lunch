/* eslint-disable no-undef */
export default () => {
  cy.visit('/');
  cy.get('button.RestaurantDropdown-toggle').click();
  cy.get('ul.RestaurantDropdown-menu li').contains('Delete').should('be.visible').click();
  cy.get('body').should('have.attr', 'class', 'modal-open');
  cy.get('.modal-footer .btn-primary').contains('Delete').click();
};
