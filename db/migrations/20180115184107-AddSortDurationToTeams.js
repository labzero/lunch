module.exports = {
  up: (queryInterface, Sequelize) => {
    queryInterface.addColumn('teams', 'sort_duration', {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 28
    });
  },

  down: (queryInterface) => {
    queryInterface.removeColumn('teams', 'sort_duration');
  }
};
