import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
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

exports.down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("restaurants", "created_at"),
    queryInterface.removeColumn("restaurants", "updated_at"),
  ]);
