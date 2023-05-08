module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS citext;');
    await queryInterface.changeColumn('users', 'email', {
      type: Sequelize.CITEXT,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('users', 'email', {
      type: Sequelize.STRING
    });
    await queryInterface.sequelize.query('DROP EXTENSION citext;');
  }
};
