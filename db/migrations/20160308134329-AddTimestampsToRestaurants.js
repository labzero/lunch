import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("restaurants", "created_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
    queryInterface.addColumn("restaurants", "updated_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
  ]);

export const down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("restaurants", "created_at"),
    queryInterface.removeColumn("restaurants", "updated_at"),
  ]);
