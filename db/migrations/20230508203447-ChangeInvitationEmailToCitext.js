module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('invitations', 'email', {
      type: Sequelize.CITEXT,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('invitations', 'email', {
      type: Sequelize.STRING
    });
  }
};
