const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => {
  const Team = db.sequelize.define('team', {
    name: Sequelize.STRING,
  }, {
    underscored: true
  });

  return Team.findOne().then(team => queryInterface.addColumn('tags', 'team_id', {
    type: Sequelize.INTEGER,
    references: {
      model: 'teams',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade',
    defaultValue: team.id
  }));
};

exports.down = queryInterface => queryInterface.removeColumn('tags', 'team_id');
