const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('votes', 'created_at', {
    type: Sequelize.DATE,
    allowNull: false
  }),
  queryInterface.addColumn('votes', 'updated_at', {
    type: Sequelize.DATE,
    allowNull: false
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('votes', 'created_at'),
  queryInterface.removeColumn('votes', 'updated_at')
);

