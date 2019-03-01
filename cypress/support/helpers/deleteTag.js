/* eslint-disable no-undef */
export default () => {
  cy.visit('/');
  cy.get('button.Tag-button').click();
};
