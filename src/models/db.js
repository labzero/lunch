// use require syntax to work with migrations
const Sequelize = require('sequelize');
const configs = require('../../database.js');

const env = process.env.NODE_ENV || 'development';
const config = configs[env];
config.operatorsAliases = { $gt: Sequelize.Op.gt, $lt: Sequelize.Op.lt };

const sequelizeInst = new Sequelize(config.database, config.username, config.password, config);

module.exports = {
  sequelize: sequelizeInst,
  DataTypes: Sequelize
};
