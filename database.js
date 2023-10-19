/* eslint-disable @typescript-eslint/no-var-requires */
require("./env");

const settings = {
  dialect: "postgres",
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASS,
  host: process.env.DB_HOST || undefined,
};

const config = {
  development: {},
  test: {
    logging: false,
  },
  production: {},
};

Object.assign(config.development, settings);
Object.assign(config.test, settings);
Object.assign(config.production, settings);

module.exports = config;
