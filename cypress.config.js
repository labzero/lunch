/* eslint-disable @typescript-eslint/no-var-requires */

const { defineConfig } = require("cypress");
require("dotenv").config({ path: "./.env.test" });

module.exports = defineConfig({
  env: {
    subdomain: "http://integration-test.local.lunch.pink:3000/",
    superuserEmail: process.env.SUPERUSER_EMAIL,
    superuserPassword: process.env.SUPERUSER_PASSWORD,
  },
  e2e: {
    baseUrl: "http://local.lunch.pink:3000/",
  },
});
