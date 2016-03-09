import config from '../../database.js';
import Sequelize from 'sequelize';

const envConfig = config[process.env.NODE_ENV];

const sequelize = new Sequelize(envConfig.database, envConfig.username, envConfig.password, envConfig);

export default sequelize;
