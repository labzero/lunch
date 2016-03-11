exports.up = (queryInterface, Sequelize) => queryInterface.createTable('votes', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  restaurant_id: {
    type: Sequelize.INTEGER,

    references: {
      model: 'restaurants',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  },
  user_id: {
    type: Sequelize.INTEGER,

    references: {
      model: 'users',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  }
});

exports.down = queryInterface => queryInterface.dropTable('votes');
