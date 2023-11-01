import path from "path";
import dotenv from "dotenv";

const env: Record<string, string | undefined> = {
  ...process.env,
};
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

Object.entries(results.parsed!).forEach(([key, value]) => {
  process.env[key] = value;
  env[key] = value;
});

export default env;
