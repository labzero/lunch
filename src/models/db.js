import { Op, Sequelize } from 'sequelize';
import configs from '../../database';

const env = (process.env.NODE_ENV || 'development');

const config = configs[env];

config.operatorsAliases = { $gt: Op.gt, $lt: Op.lt };

export const sequelize = new Sequelize(config.database, config.username, config.password, config);
export { DataTypes, Op } from 'sequelize';
