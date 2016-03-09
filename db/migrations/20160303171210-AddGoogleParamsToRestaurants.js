const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('restaurants', 'place_id', {
    type: Sequelize.STRING,
    indicesType: 'UNIQUE'
  }),
  queryInterface.addColumn('restaurants', 'lat', {
    type: Sequelize.FLOAT
  }),
  queryInterface.addColumn('restaurants', 'lng', {
    type: Sequelize.FLOAT
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('restaurants', 'place_id'),
  queryInterface.removeColumn('restaurants', 'lat'),
  queryInterface.removeColumn('restaurants', 'lng')
);
