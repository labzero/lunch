/* eslint-disable no-undef */
export default () => {
  const address = '77 bat';
  const lat = 37.7919401;
  const lng = -122.4000474;
  const name = 'test';
  const slug = 'integration-test';

  cy.request('POST', `${Cypress.config().baseUrl}/api/teams`, {
    lat,
    lng,
    name,
    slug,
    address
  });
  cy.visit('/');
};
