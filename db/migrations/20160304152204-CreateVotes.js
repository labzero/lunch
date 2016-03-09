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
    }
  },
  user_id: {
    type: Sequelize.INTEGER,

    references: {
      model: 'users',
      key: 'id'
    }
  }
});

exports.down = queryInterface => queryInterface.dropTable('votes');
