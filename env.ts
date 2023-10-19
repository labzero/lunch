import path from "path";
import dotenv from "dotenv";

// This shouldn't exist if Bun worked correctly, but:
// https://github.com/oven-sh/bun/issues/6334
if (process.env.NODE_ENV === "test") {
  dotenv.config({
    override: true,
    path: path.resolve(process.cwd(), ".env.test"),
  });
} else {
  dotenv.config();
}
