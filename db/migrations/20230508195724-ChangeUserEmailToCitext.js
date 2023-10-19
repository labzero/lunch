import { DataTypes } from "sequelize";

module.exports = {
  async up({ context: queryInterface }) {
    await queryInterface.sequelize.query(
      "CREATE EXTENSION IF NOT EXISTS citext;"
    );
    await queryInterface.changeColumn("users", "email", {
      type: DataTypes.CITEXT,
    });
  },

  async down({ context: queryInterface }) {
    await queryInterface.changeColumn("users", "email", {
      type: DataTypes.STRING,
    });
    await queryInterface.sequelize.query("DROP EXTENSION citext;");
  },
};
