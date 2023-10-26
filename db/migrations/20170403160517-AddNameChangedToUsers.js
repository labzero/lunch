import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("users", "name_changed", {
    defaultValue: false,
    type: DataTypes.BOOLEAN,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("users", "name_changed");
