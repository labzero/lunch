/* eslint-disable @typescript-eslint/no-var-requires */

const { defineConfig } = require("cypress");
require("dotenv").config({ path: "./.env.test" });

const protocol = process.env.USE_HTTPS === "true" ? "https://" : "http://";

module.exports = defineConfig({
  port: 4000,
  env: {
    subdomain: `${protocol}integration-test.local.lunch.pink:3000/`,
    superuserEmail: process.env.SUPERUSER_EMAIL,
    superuserPassword: process.env.SUPERUSER_PASSWORD,
  },
  e2e: {
    baseUrl: `${protocol}local.lunch.pink:3000/`,
  },
});
