exports.up = (queryInterface, Sequelize) =>
  queryInterface.addColumn('restaurants', 'team_id', {
    type: Sequelize.INTEGER,
    references: {
      model: 'teams',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  });

exports.down = queryInterface =>
  queryInterface.removeColumn('restaurants', 'team_id');
