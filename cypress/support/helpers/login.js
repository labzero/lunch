/* eslint-disable no-undef */
export default () => {
  const email = 'test@lunch.pink';
  const password = 'test';
  cy.request('POST', '/login', {
    email,
    password
  });
  cy.visit('/');
};
