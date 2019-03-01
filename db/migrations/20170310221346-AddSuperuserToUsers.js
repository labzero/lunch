const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('users', 'superuser', {
  allowNull: false,
  type: Sequelize.BOOLEAN,
  defaultValue: false
}).then(() => {
  const User = db.sequelize.define('user', {
    google_id: Sequelize.STRING,
    name: Sequelize.STRING,
    email: Sequelize.STRING,
    superuser: Sequelize.BOOLEAN
  }, {
    underscored: true
  });

  return User.update({
    superuser: true
  }, {
    where: {
      email: 'jeffrey@labzero.com'
    }
  });
});

exports.down = queryInterface => queryInterface.removeColumn('users', 'superuser');
