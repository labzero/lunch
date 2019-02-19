const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => queryInterface.changeColumn('tags', 'name', {
  type: Sequelize.STRING,
  allowNull: false,
  unique: false
}).then(() => db.sequelize.query('ALTER TABLE tags DROP CONSTRAINT IF EXISTS tags_name_key;'));

exports.down = (queryInterface, Sequelize) => queryInterface.changeColumn('tags', 'name', {
  type: Sequelize.STRING,
  unique: true
});
