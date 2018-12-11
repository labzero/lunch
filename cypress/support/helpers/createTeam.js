/* eslint-disable no-undef */
export default () => {
    const address = "77 bat";
    const lat = 37.7919401;
    const lng = -122.4000474;
    const name = "test";
    const slug = "integration-test";

    cy.request('POST', 'https://local.lunch.pink:3000/api/teams', {
        lat,
        lng,
        name,
        slug,
        address
    });
    cy.visit('/');

};
