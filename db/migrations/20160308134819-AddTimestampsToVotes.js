import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("votes", "created_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
    queryInterface.addColumn("votes", "updated_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
  ]);

export const down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("votes", "created_at"),
    queryInterface.removeColumn("votes", "updated_at"),
  ]);
