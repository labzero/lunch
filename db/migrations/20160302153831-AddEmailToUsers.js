import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.addColumn("users", "email", {
    type: DataTypes.STRING,
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("users", "email");
