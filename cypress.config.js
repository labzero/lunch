/* eslint-disable @typescript-eslint/no-var-requires */

const { defineConfig } = require("cypress");
require("dotenv").config({ path: "./.env.test" });

module.exports = defineConfig({
  port: 4000,
  env: {
    subdomain: "https://integration-test.local.lunch.pink:3000/",
    superuserEmail: process.env.SUPERUSER_EMAIL,
    superuserPassword: process.env.SUPERUSER_PASSWORD,
  },
  e2e: {
    baseUrl: "https://local.lunch.pink:3000/",
  },
});
