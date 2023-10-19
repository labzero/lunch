import { DataTypes } from "sequelize";

module.exports = {
  async up({ context: queryInterface }) {
    await queryInterface.changeColumn("invitations", "email", {
      type: DataTypes.CITEXT,
    });
  },

  async down({ context: queryInterface }) {
    await queryInterface.changeColumn("invitations", "email", {
      type: DataTypes.STRING,
    });
  },
};
