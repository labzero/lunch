/* eslint-disable no-undef, camelcase */

export default () => {
  const address = "One Ferry Building, San Francisco, CA 94111, USA";
  const lat = 37.7955703;
  const lng = -122.39332079999997;
  const name = "Ferry Building Marketplace";
  const placeId = "ChIJWTGPjmaAhYARxz6l1hOj92w";
  cy.request("POST", `${Cypress.env("subdomain")}api/restaurants`, {
    name,
    placeId,
    address,
    lat,
    lng,
  });
};
