const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => {
  const Team = db.sequelize.define('team', {
    name: Sequelize.STRING,
  }, {
    underscored: true
  });

  return queryInterface.createTable('teams', {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: Sequelize.INTEGER
    },
    name: {
      allowNull: false,
      type: Sequelize.STRING,
    },
    created_at: {
      allowNull: false,
      type: Sequelize.DATE
    },
    updated_at: {
      allowNull: false,
      type: Sequelize.DATE
    }
  }).then(() => Team.create({
    name: 'Lab Zero'
  }));
};

exports.down = queryInterface => queryInterface.dropTable('teams');
