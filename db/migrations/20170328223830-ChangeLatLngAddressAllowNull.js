const Promise = require('bluebird');
const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => {
  const Team = db.sequelize.define('team', {
    name: Sequelize.STRING,
    slug: Sequelize.STRING(63),
    lat: Sequelize.DOUBLE,
    lng: Sequelize.DOUBLE,
    address: Sequelize.STRING
  }, {
    underscored: true
  });

  return Team.update({
    address: '77 Battery Street, San Francisco, CA 94111, USA',
    lat: 37.79195,
    lng: -122.399991
  }, {
    where: { slug: 'labzero' }
  }).then(() => Promise.all(
    queryInterface.changeColumn('teams', 'lat', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    }),
    queryInterface.changeColumn('teams', 'lng', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    })
  ));
};

exports.down = (queryInterface, Sequelize) => Promise.all(
  queryInterface.changeColumn('teams', 'lat', {
    allowNull: true,
    type: Sequelize.DOUBLE
  }),
  queryInterface.changeColumn('teams', 'lng', {
    allowNull: true,
    type: Sequelize.DOUBLE
  })
);
