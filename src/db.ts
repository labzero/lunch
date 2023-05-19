import { Op } from "sequelize";
import { Sequelize, SequelizeOptions } from "sequelize-typescript";
import configs from "../database";

import Decision from "./models/Decision";
import Invitation from "./models/Invitation";
import Restaurant from "./models/Restaurant";
import RestaurantTag from "./models/RestaurantTag";
import Role from "./models/Role";
import Tag from "./models/Tag";
import Team from "./models/Team";
import User from "./models/User";
import Vote from "./models/Vote";

const env = process.env.NODE_ENV || "development";

const config = (configs as { [index: string]: SequelizeOptions })[env];

config.operatorsAliases = { $gt: Op.gt, $lt: Op.lt };

export const sequelize = new Sequelize(
  config.database!,
  config.username!,
  config.password,
  config
);

sequelize.addModels([
  Decision,
  Invitation,
  Restaurant,
  RestaurantTag,
  Role,
  Tag,
  Team,
  User,
  Vote,
]);

export {
  Decision,
  Invitation,
  Restaurant,
  RestaurantTag,
  Role,
  Tag,
  Team,
  User,
  Vote,
};
