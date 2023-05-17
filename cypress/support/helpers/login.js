/* eslint-disable no-undef */
const superuserEmail = Cypress.env("superuserEmail");
const superuserPassword = Cypress.env("superuserPassword");

export default () => {
  const email = superuserEmail;
  const password = superuserPassword;
  cy.request("POST", "/login", {
    email,
    password,
  });
  cy.visit("/");
};
