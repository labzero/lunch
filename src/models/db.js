import configs from '../../database.js';
import Sequelize from 'sequelize';

const env = process.env.NODE_ENV || 'development';
const config = configs[env];

let sequelizeInst;

if (config.use_env_variable) {
  sequelizeInst = new Sequelize(process.env[config.use_env_variable]);
} else {
  sequelizeInst = new Sequelize(config.database, config.username, config.password, config);
}

export const sequelize = sequelizeInst;

export const DataTypes = Sequelize;
