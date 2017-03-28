const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('teams', 'lat', {
    type: Sequelize.DOUBLE
  }),
  queryInterface.addColumn('teams', 'lng', {
    type: Sequelize.DOUBLE
  }),
  queryInterface.addColumn('teams', 'address', {
    type: Sequelize.STRING
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('teams', 'lat'),
  queryInterface.removeColumn('teams', 'lng'),
  queryInterface.removeColumn('teams', 'address')
);
