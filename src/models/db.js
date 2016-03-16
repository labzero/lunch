import configs from '../../database.js';
import Sequelize from 'sequelize';

const env = process.env.NODE_ENV || 'development';
const config = configs[env];
export let sequelize;

if (config.use_env_variable) {
  sequelize = new Sequelize(process.env[config.use_env_variable]);
} else {
  sequelize = new Sequelize(config.database, config.username, config.password, config);
}

export const DataTypes = Sequelize;
