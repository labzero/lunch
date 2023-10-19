import { DataTypes } from "sequelize";

module.exports = {
  up: ({ context: queryInterface }) =>
    queryInterface.addColumn("teams", "sort_duration", {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 28,
    }),

  down: ({ context: queryInterface }) =>
    queryInterface.removeColumn("teams", "sort_duration"),
};
