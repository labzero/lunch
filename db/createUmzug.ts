import { Umzug, SequelizeStorage } from "umzug";
import { sequelize } from "../src/db";
import "../env";

export default (files = "./migrations/*.js") =>
  new Umzug({
    migrations: { glob: [files, { cwd: __dirname }] },
    context: sequelize.getQueryInterface(),
    storage: new SequelizeStorage({ sequelize }),
    logger: console,
  });
