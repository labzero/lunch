import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("restaurants", "address", {
    type: DataTypes.STRING,
    allowNull: false,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("restaurants", "address");
