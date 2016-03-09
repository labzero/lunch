const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('restaurants', 'created_at', {
    type: Sequelize.DATE,
    allowNull: false
  }),
  queryInterface.addColumn('restaurants', 'updated_at', {
    type: Sequelize.DATE,
    allowNull: false
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('restaurants', 'created_at'),
  queryInterface.removeColumn('restaurants', 'updated_at')
);

