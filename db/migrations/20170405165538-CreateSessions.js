exports.up = (queryInterface, Sequelize) => queryInterface.createTable('Sessions', {
  sid: {
    type: Sequelize.STRING(32),
    primaryKey: true
  },
  expires: Sequelize.DATE,
  data: Sequelize.TEXT,
  createdAt: Sequelize.DATE,
  updatedAt: Sequelize.DATE
});

exports.down = queryInterface => queryInterface.dropTable('Sessions');
