/* eslint-disable @typescript-eslint/no-var-requires */
import path from "path";
import dotenv from "dotenv";

let results;
// This shouldn't exist if Bun worked correctly, but:
// https://github.com/oven-sh/bun/issues/6334
if (process.env.NODE_ENV === "test") {
  results = dotenv.config({
    override: true,
    path: path.resolve(process.cwd(), ".env.test"),
  });
} else {
  results = dotenv.config({
    path: path.resolve(process.cwd(), ".env"),
  });
}

const settings = {
  dialect: "postgres",
  database: results.DB_NAME || process.env.DB_NAME,
  username: results.DB_USER || process.env.DB_USER,
  password: results.DB_PASS || process.env.DB_PASS,
  host: results.DB_HOST || process.env.DB_HOST || undefined,
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

export default config;
