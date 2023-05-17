/* eslint-disable no-undef */
import * as helpers from "../../support/helpers";

const superuserEmail = Cypress.env("superuserEmail");
const superuserPassword = Cypress.env("superuserPassword");

describe("login page", () => {
  beforeEach(() => {
    cy.visit("/login");
  });

  it("contains email and password fields, Google login, and forgot password link", () => {
    cy.contains("Email/password");
    cy.contains("Sign in with Google");
    cy.contains("Forgot password?");
  });

  it("logs in and out successfully", () => {
    cy.get("#login-email").type(superuserEmail);
    cy.get("#login-password").type(superuserPassword);
    cy.get('button[type="submit"]').click();
    helpers.deleteTeam();
    cy.contains("You’re not currently a part of any teams!");

    cy.get("#header button").click();
    cy.get("nav.Menu-root.Menu-open a").contains("Log Out").click();
    cy.contains("Figure it out");
  });
});
