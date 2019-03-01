/* eslint-disable no-undef */
export default () => {
  cy.visit('/');
  cy.get('.Restaurant-tagsArea button').first().click();
  cy.get('.RestaurantAddTagFormAutosuggest-container input[type="text"]').type('waterfront');
  cy.get('.RestaurantAddTagForm-root button[type="submit"]').click();
  cy.get('.RestaurantAddTagForm-root button[type="button"]').click();
};
