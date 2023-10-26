import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("teams", "sort_duration", {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 28,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("teams", "sort_duration");
