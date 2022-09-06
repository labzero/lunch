const { defineConfig } = require('cypress');

module.exports = defineConfig({
  port: 4000,
  env: {
    subdomain: 'https://integration-test.local.lunch.pink:3000/',
  },
  e2e: {
    baseUrl: 'https://local.lunch.pink:3000/',
  },
});
