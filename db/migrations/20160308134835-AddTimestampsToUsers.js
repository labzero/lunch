const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('users', 'created_at', {
    type: Sequelize.DATE,
    allowNull: false
  }),
  queryInterface.addColumn('users', 'updated_at', {
    type: Sequelize.DATE,
    allowNull: false
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('users', 'created_at'),
  queryInterface.removeColumn('users', 'updated_at')
);

