import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("users", "email", {
    type: DataTypes.STRING,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("users", "email");
