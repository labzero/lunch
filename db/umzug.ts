// index.js
import { Umzug, SequelizeStorage } from "umzug";
import { sequelize } from "../src/db";

export default new Umzug({
  migrations: { glob: ["./migrations/*.js", { cwd: __dirname }] },
  context: sequelize.getQueryInterface(),
  storage: new SequelizeStorage({ sequelize }),
  logger: console,
});
