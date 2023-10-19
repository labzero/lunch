import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("users", "created_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
    queryInterface.addColumn("users", "updated_at", {
      type: DataTypes.DATE,
      allowNull: false,
    }),
  ]);

exports.down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("users", "created_at"),
    queryInterface.removeColumn("users", "updated_at"),
  ]);
