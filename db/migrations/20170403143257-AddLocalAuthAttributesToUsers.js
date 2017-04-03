const Promise = require('bluebird');

exports.up = (queryInterface, Sequelize) => Promise.all(
  queryInterface.addColumn('users', 'encrypted_password', {
    type: Sequelize.STRING
  }),
  queryInterface.addColumn('users', 'reset_password_token', {
    type: Sequelize.STRING,
    unique: true
  }),
  queryInterface.addColumn('users', 'reset_password_sent_at', {
    type: Sequelize.DATE
  }),
  queryInterface.addColumn('users', 'confirmation_token', {
    type: Sequelize.STRING,
    unique: true
  }),
  queryInterface.addColumn('users', 'confirmed_at', {
    type: Sequelize.DATE
  }),
  queryInterface.addColumn('users', 'confirmation_sent_at', {
    type: Sequelize.DATE
  })
);

exports.down = queryInterface => Promise.all(
  queryInterface.removeColumn('users', 'encrypted_password'),
  queryInterface.removeColumn('users', 'reset_password_token'),
  queryInterface.removeColumn('users', 'reset_password_sent_at'),
  queryInterface.removeColumn('users', 'confirmation_token'),
  queryInterface.removeColumn('users', 'confirmed_at'),
  queryInterface.removeColumn('users', 'confirmation_sent_at')
);
