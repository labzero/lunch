const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => queryInterface.changeColumn('users', 'google_id', {
  type: Sequelize.STRING
});

exports.down = (queryInterface, Sequelize) => {
  const User = db.sequelize.define('user', {
    google_id: Sequelize.STRING,
  }, {
    underscored: true
  });

  User.destroy({ where: { google_id: null } }).then(() => queryInterface.changeColumn('users', 'google_id', {
    type: Sequelize.STRING,
    allowNull: false
  }));
};
