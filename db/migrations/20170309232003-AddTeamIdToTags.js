exports.up = (queryInterface, Sequelize) =>
  queryInterface.addColumn('tags', 'team_id', {
    type: Sequelize.INTEGER,
    references: {
      model: 'teams',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  });

exports.down = queryInterface =>
  queryInterface.removeColumn('tags', 'team_id');
