const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => {
  const Team = db.sequelize.define('team', {
    name: Sequelize.STRING,
    slug: Sequelize.STRING
  }, {
    underscored: true
  });

  return Team.update({ slug: 'labzero' }, { where: { name: 'Lab Zero' } }).then(() =>
    queryInterface.changeColumn('teams', 'slug', {
      allowNull: false,
      type: Sequelize.STRING
    }));
};

exports.down = (queryInterface, Sequelize) =>
  queryInterface.changeColumn('teams', 'slug', {
    allowNull: true,
    type: Sequelize.STRING
  });
